// Command format assembles a JSON document from the environment, checks it
// against a contract and writes it to standard output.
//
//	format CONTRACT FIELD...
//
// Each FIELD names both a field of the document and the variable its value is
// read from, so nothing but names is ever passed on a command line. That is the
// mirror of parse, which reads a document and writes the assignments that put
// its fields into those same variables.
//
// A named field whose variable is not set is an error. No contract here has an
// optional field, so there is no document with something missing from it to
// build: which shape is being built is said by which names are given.
package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/thruput-io/gettoken/components/contract"
)

func written(value string) any {
	var already any
	if err := json.Unmarshal([]byte(value), &already); err != nil {
		return value
	}
	return already
}

func run() error {
	if len(os.Args) < 2 {
		return fmt.Errorf("usage: format CONTRACT [FIELD ...]")
	}
	governing, err := contract.Open(contract.Directory(), os.Args[1])
	if err != nil {
		return err
	}
	values := map[string]any{}
	for _, field := range os.Args[2:] {
		if _, named := values[field]; named {
			return fmt.Errorf("%s is named twice", field)
		}
		text, set := os.LookupEnv(field)
		if !set {
			return fmt.Errorf("%s is not set, so there is no value for the field of that name", field)
		}
		values[field] = written(text)
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
