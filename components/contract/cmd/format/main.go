// Command format assembles a JSON document from its arguments, checks it
// against a contract and writes it to standard output.
//
// A value goes into the document as it stands. Only a string needs quoting, so
// the only value that gets quoted is one that is not already JSON:
//
//	FIELD=VALUE   the value as written, taken as a string if it is not JSON
//	FIELD@PATH    the contents of PATH, always a string; - is standard input
//
// Nothing here asks a contract what type a field has. Each argument carries
// what it carries, and the contract then says whether that was allowed.
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/thruput-io/gettoken/components/contract"
)

func contents(path string) (string, error) {
	if path == "-" {
		raw, err := io.ReadAll(os.Stdin)
		return string(raw), err
	}
	raw, err := os.ReadFile(path)
	return string(raw), err
}

// written takes a value as the JSON it already is, or as the string it can only
// be if it is not JSON.
func written(value string) any {
	var already any
	if err := json.Unmarshal([]byte(value), &already); err != nil {
		return value
	}
	return already
}

// filling reads one argument as the field it fills and the value it carries.
// The operator that comes first decides where the value is read from, so a
// value that happens to contain the other operator is not mistaken for it.
func filling(argument string) (string, any, error) {
	at := strings.IndexByte(argument, '@')
	is := strings.IndexByte(argument, '=')

	if at >= 0 && (is < 0 || at < is) {
		text, err := contents(argument[at+1:])
		if err != nil {
			return "", nil, err
		}
		return argument[:at], text, nil
	}
	if is < 0 {
		return "", nil, fmt.Errorf("%q fills no field: write FIELD=VALUE or FIELD@PATH", argument)
	}
	return argument[:is], written(argument[is+1:]), nil
}

func run() error {
	if len(os.Args) < 2 {
		return fmt.Errorf("usage: format CONTRACT [FIELD=VALUE|FIELD@PATH ...]")
	}
	governing, err := contract.Open(contract.Directory(), os.Args[1])
	if err != nil {
		return err
	}
	values := map[string]any{}
	for _, argument := range os.Args[2:] {
		field, value, err := filling(argument)
		if err != nil {
			return err
		}
		if _, filled := values[field]; filled {
			return fmt.Errorf("%s is filled twice", field)
		}
		values[field] = value
	}
	document, err := governing.Build(values)
	if err != nil {
		return err
	}
	fmt.Println(string(document.JSON()))
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "format: %v\n", err)
		os.Exit(1)
	}
}
