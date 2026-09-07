package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"

	"github.com/thruput-io/gettoken/components/contract"
)

func run() error {
	if len(os.Args) < 2 {
		return fmt.Errorf("usage: parse CONTRACT [FIELD ...]")
	}
	governing, err := contract.Open(os.Args[1])
	if err != nil {
		return err
	}
	raw, err := io.ReadAll(os.Stdin)
	if err != nil {
		return err
	}
	var document any
	if err := json.Unmarshal(raw, &document); err != nil {
		return fmt.Errorf("the document is not JSON: %w", err)
	}
	if err := governing.Check(document); err != nil {
		return err
	}
	fields, _ := document.(map[string]any)
	for _, field := range os.Args[2:] {
		text := "''"
		if value := fields[field]; value != nil {
			if text, err = contract.Shell(value); err != nil {
				return err
			}
		}
		fmt.Printf("%s=%s\n", field, text)
	}
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "parse: %v\n", err)
		os.Exit(1)
	}
}
