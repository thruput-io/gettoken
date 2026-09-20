// Command serve is the door a component answers at.
//
//	serve --request CONTRACT [--request CONTRACT]... --response CONTRACT
//	      [--field NAME] --answers PATH -- [-f FILE] (PAYLOAD | --stdin)
//
// Left of -- the component says what it is: which asks it takes, what it
// answers with, and what answers. Right of -- is the caller's half, and nothing
// in it reaches the left: a caller says what it is asking and where the answer
// goes, never what runs or what governs it.
//
// The caller's half is the same for every component, which is the point. A
// payload is an argument, so a component can be exercised from a shell without
// a pipeline; --stdin takes it from standard input instead, for a payload too
// large or too private to put on a command line; -f writes the answer to a file
// closed to everyone but its owner, rather than to standard output.
//
// What answers reads one document on standard input and writes one on standard
// output, and is told nothing about how it was reached. That is what leaves the
// transport free to become something else — a socket, a listener, a daemon on
// the privileged side of a boundary — without the component noticing.
//
// Both directions are held to their contracts here, so a component cannot be
// told something its contract refuses, and cannot answer something the caller's
// contract does not admit. Nothing is written until the answer has been
// admitted: a failure leaves standard output empty and the file untouched.
package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/thruput-io/gettoken/components/contract"
)

// suffix is what a door's name is to what answers at it. A door invoked as
// token-service is answered by token-service.answers, and says so itself, so
// the two are one deployment decision rather than two.
const suffix = ".answers"

// admittedBy names the contract that admitted the ask, for a component that
// takes more than one shape. A component reading one shape never looks at it.
const admittedBy = "REQUEST_CONTRACT"

// A door is what a component says about itself.
type door struct {
	requests []string
	response string
	field    string
	answers  string
	name     string
}

// A reach is how a caller came to the door.
type reach struct {
	payload []byte
	into    string
}

func described(args []string) (door, error) {
	described := door{}
	for len(args) > 0 {
		named := args[0]
		if len(args) < 2 {
			return described, fmt.Errorf("%s names nothing", named)
		}
		value := args[1]
		args = args[2:]
		switch named {
		case "--request":
			described.requests = append(described.requests, value)
		case "--response":
			described.response = value
		case "--field":
			described.field = value
		case "--answers":
			described.answers = value
		default:
			return described, fmt.Errorf("%s is not something a door is described with", named)
		}
	}
	if len(described.requests) == 0 {
		return described, errors.New("a door takes at least one ask: name it with --request")
	}
	if described.response == "" {
		return described, errors.New("a door answers one shape: name it with --response")
	}
	if described.answers == "" {
		return described, errors.New("a door has something behind it: name it with --answers")
	}
	described.name = strings.TrimSuffix(filepath.Base(described.answers), suffix)
	return described, nil
}

func (d door) usage() error {
	return fmt.Errorf("usage: %s [-f FILE] (PAYLOAD | --stdin)", d.name)
}

func (d door) reached(args []string, in io.Reader) (reach, error) {
	came := reach{}
	said, fromStandardInput := false, false
	for len(args) > 0 {
		switch args[0] {
		case "-f":
			if len(args) < 2 {
				return came, d.usage()
			}
			came.into = args[1]
			args = args[2:]
		case "--stdin":
			fromStandardInput = true
			args = args[1:]
		default:
			if said {
				return came, d.usage()
			}
			came.payload = []byte(args[0])
			said = true
			args = args[1:]
		}
	}
	if said == fromStandardInput {
		return came, d.usage()
	}
	if fromStandardInput {
		read, err := io.ReadAll(in)
		if err != nil {
			return came, err
		}
		came.payload = read
	}
	return came, nil
}

// admits hands the payload to each ask the door takes and reports the one that
// admitted it. Exactly one may: a payload no contract admits is refused with
// what each of them said, and a payload two admit says the shapes overlap,
// which is the door's error and not the caller's.
func (d door) admits(directory string, payload []byte) (string, contract.Document, error) {
	admitting, refusals := "", []string{}
	var admitted contract.Document
	for _, named := range d.requests {
		governing, err := contract.Open(directory, named)
		if err != nil {
			return "", nil, err
		}
		held, err := governing.Hold(payload)
		if err != nil {
			refusals = append(refusals, err.Error())
			continue
		}
		if admitted != nil {
			return "", nil, fmt.Errorf("%s and %s both admit this ask, so which was asked cannot be told", admitting, named)
		}
		admitting, admitted = named, held
	}
	if admitted == nil {
		return "", nil, errors.New(strings.Join(refusals, "\n"))
	}
	return admitting, admitted, nil
}

// answered runs what is behind the door with the ask on standard input and
// hands back what it wrote. A component that fails has already said why on
// standard error, so the status it left with is carried out and nothing is
// added to what it said.
func (d door) answered(admitting string, ask contract.Document, complaints io.Writer) ([]byte, int, error) {
	answering := exec.Command(d.answers)
	answering.Env = append(os.Environ(), admittedBy+"="+admitting)
	answering.Stdin = bytes.NewReader(ask.JSON())
	written := bytes.Buffer{}
	answering.Stdout = &written
	answering.Stderr = complaints
	err := answering.Run()
	if err == nil {
		return written.Bytes(), 0, nil
	}
	failed := &exec.ExitError{}
	if errors.As(err, &failed) && failed.ExitCode() > 0 {
		return nil, failed.ExitCode(), nil
	}
	if errors.As(err, &failed) {
		return nil, 1, fmt.Errorf("what answers at %s was stopped before it answered", d.answers)
	}
	return nil, 1, fmt.Errorf("nothing answers at %s: %w", d.answers, err)
}

// says renders the answer for the caller: the document as it was admitted, or
// the one field the door hands over as text, for a caller that is not owed the
// rest of it.
func (d door) says(answer contract.Document) ([]byte, error) {
	if d.field == "" {
		return append(bytes.TrimSpace(answer.JSON()), '\n'), nil
	}
	value, carried := answer.Value(d.field)
	if !carried {
		return nil, fmt.Errorf("the answer carries no %s", d.field)
	}
	text, spelled := value.(string)
	if !spelled {
		encoded, err := json.Marshal(value)
		if err != nil {
			return nil, err
		}
		text = string(encoded)
	}
	return []byte(text + "\n"), nil
}

// hands over what was said, to standard output or to the file the caller named.
// A file is made closed to everyone but its owner, and made so again if it was
// already there, because what travels this way is as often a credential as not.
func (came reach) handsOver(said []byte, out io.Writer) error {
	if came.into == "" {
		_, err := out.Write(said)
		return err
	}
	file, err := os.OpenFile(came.into, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0o600)
	if err != nil {
		return err
	}
	if err := file.Chmod(0o600); err != nil {
		file.Close()
		return err
	}
	if _, err := file.Write(said); err != nil {
		file.Close()
		return err
	}
	return file.Close()
}

func run(args []string, in io.Reader, out io.Writer, complaints io.Writer) int {
	split := -1
	for at, arg := range args {
		if arg == "--" {
			split = at
			break
		}
	}
	if split < 0 {
		fmt.Fprintln(complaints, "serve: a door is described left of -- and reached right of it")
		return 1
	}
	serving, err := described(args[:split])
	if err != nil {
		fmt.Fprintf(complaints, "serve: %v\n", err)
		return 1
	}
	failed := func(err error) int {
		fmt.Fprintf(complaints, "%s: %v\n", serving.name, err)
		return 1
	}
	came, err := serving.reached(args[split+1:], in)
	if err != nil {
		return failed(err)
	}
	directory := contract.Directory()
	admitting, ask, err := serving.admits(directory, came.payload)
	if err != nil {
		return failed(err)
	}
	answer, status, err := serving.answered(admitting, ask, complaints)
	if err != nil {
		return failed(err)
	}
	if status != 0 {
		return status
	}
	governing, err := contract.Open(directory, serving.response)
	if err != nil {
		return failed(err)
	}
	held, err := governing.Hold(answer)
	if err != nil {
		return failed(err)
	}
	said, err := serving.says(held)
	if err != nil {
		return failed(err)
	}
	if err := came.handsOver(said, out); err != nil {
		return failed(err)
	}
	return 0
}

func main() {
	os.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))
}
