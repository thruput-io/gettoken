package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/thruput-io/gettoken/components/contract"
)

func held(path string) (string, error) {
	if path == "-" {
		raw, err := io.ReadAll(os.Stdin)
		return string(raw), err
	}
	raw, err := os.ReadFile(path)
	return string(raw), err
}

func run() error {
	if len(os.Args) < 2 {
		return fmt.Errorf("usage: format CONTRACT [FIELD=VALUE|FIELD=@FILE ...]")
	}
	governing, err := contract.Open(os.Args[1])
	if err != nil {
		return err
	}
	document := map[string]any{}
	for _, argument := range os.Args[2:] {
		field, text, named := strings.Cut(argument, "=")
		if !named {
			return fmt.Errorf("%q names no field", argument)
		}
		kind, err := governing.Kind(field)
		if err != nil {
			return err
		}
		if path, reading := strings.CutPrefix(text, "@"); reading {
			if text, err = held(path); err != nil {
				return err
			}
		}
		value, err := kind.Read(text)
		if err != nil {
			return fmt.Errorf("%s: %w", field, err)
		}
		document[field] = value
	}
	if err := governing.Check(document); err != nil {
		return err
	}
	encoded, err := json.Marshal(document)
	if err != nil {
		return err
	}
	fmt.Println(string(encoded))
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "format: %v\n", err)
		os.Exit(1)
	}
}
