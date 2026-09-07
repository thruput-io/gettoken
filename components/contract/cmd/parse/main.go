// Command parse checks a JSON document on standard input against a contract and
// writes the fields it was asked for as shell assignments.
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/thruput-io/gettoken/components/contract"
)

// assignable quotes value so that a shell reading the assignment gets the value
// back whole, whatever it carries.
func assignable(value any) (string, error) {
	text, spelled := value.(string)
	if !spelled {
		encoded, err := json.Marshal(value)
		if err != nil {
			return "", err
		}
		text = string(encoded)
	}
	return "'" + strings.ReplaceAll(text, "'", `'\''`) + "'", nil
}

func run() error {
	if len(os.Args) < 2 {
		return fmt.Errorf("usage: parse CONTRACT [FIELD ...]")
	}
	governing, err := contract.Open(contract.Directory(), os.Args[1])
	if err != nil {
		return err
	}
	raw, err := io.ReadAll(os.Stdin)
	if err != nil {
		return err
	}
	document, err := governing.Hold(raw)
	if err != nil {
		return err
	}
	for _, field := range os.Args[2:] {
		assignment := "''"
		if value, carried := document.Value(field); carried && value != nil {
			if assignment, err = assignable(value); err != nil {
				return err
			}
		}
		fmt.Printf("%s=%s\n", field, assignment)
	}
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "parse: %v\n", err)
		os.Exit(1)
	}
}
