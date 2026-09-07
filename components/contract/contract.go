package contract

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/google/jsonschema-go/jsonschema"
)

const namespace = "https://thruput.io/gettoken/"

type Kind int

const (
	Text Kind = iota
	Number
	Boolean
)

type Contract struct {
	name      string
	directory string
	root      *jsonschema.Schema
	resolved  *jsonschema.Resolved
}

func directory() string {
	if named := os.Getenv("CONTRACTS_DIR"); named != "" {
		return named
	}
	return "/usr/share/gettoken/contracts"
}

func read(from, name string) (*jsonschema.Schema, error) {
	raw, err := os.ReadFile(filepath.Join(from, name))
	if err != nil {
		return nil, err
	}
	schema := new(jsonschema.Schema)
	if err := json.Unmarshal(raw, schema); err != nil {
		return nil, err
	}
	return schema, nil
}

func Open(name string) (*Contract, error) {
	from := directory()
	root, err := read(from, name)
	if err != nil {
		return nil, fmt.Errorf("no contract named %s in %s", name, from)
	}
	resolved, err := root.Resolve(&jsonschema.ResolveOptions{
		BaseURI: namespace + name,
		Loader: func(reference *url.URL) (*jsonschema.Schema, error) {
			return read(from, filepath.Base(reference.Path))
		},
	})
	if err != nil {
		return nil, fmt.Errorf("contract %s does not resolve: %w", name, err)
	}
	return &Contract{name: name, directory: from, root: root, resolved: resolved}, nil
}

func (c *Contract) Check(document any) error {
	if err := c.resolved.Validate(document); err != nil {
		return fmt.Errorf("the document does not satisfy %s\n%w", c.name, err)
	}
	return nil
}

func (c *Contract) governing(schema *jsonschema.Schema, field string) *jsonschema.Schema {
	if schema == nil {
		return nil
	}
	if named := schema.Properties[field]; named != nil {
		return named
	}
	for _, branches := range [][]*jsonschema.Schema{schema.OneOf, schema.AnyOf, schema.AllOf} {
		for _, branch := range branches {
			if found := c.governing(branch, field); found != nil {
				return found
			}
		}
	}
	return nil
}

func (c *Contract) following(reference string) (*jsonschema.Schema, error) {
	file, pointer, _ := strings.Cut(reference, "#")
	root := c.root
	if file != "" {
		var err error
		if root, err = read(c.directory, file); err != nil {
			return nil, err
		}
	}
	named, found := strings.CutPrefix(pointer, "/$defs/")
	if !found {
		return nil, fmt.Errorf("%s references %s, which this reads no form of", c.name, reference)
	}
	target := root.Defs[named]
	if target == nil {
		return nil, fmt.Errorf("%s references %s, which is not there", c.name, reference)
	}
	return target, nil
}

func (c *Contract) Kind(field string) (Kind, error) {
	schema := c.governing(c.root, field)
	if schema == nil {
		return Text, fmt.Errorf("%s governs no field named %s", c.name, field)
	}
	for schema.Ref != "" {
		followed, err := c.following(schema.Ref)
		if err != nil {
			return Text, err
		}
		schema = followed
	}
	if schema.Const != nil {
		switch (*schema.Const).(type) {
		case bool:
			return Boolean, nil
		case float64:
			return Number, nil
		}
		return Text, nil
	}
	types := schema.Types
	if schema.Type != "" {
		types = []string{schema.Type}
	}
	for _, named := range types {
		switch named {
		case "boolean":
			return Boolean, nil
		case "integer", "number":
			return Number, nil
		case "string":
			return Text, nil
		}
	}
	return Text, fmt.Errorf("%s says no type for %s", c.name, field)
}

func (k Kind) Read(text string) (any, error) {
	switch k {
	case Boolean:
		return strconv.ParseBool(text)
	case Number:
		if whole, err := strconv.ParseInt(text, 10, 64); err == nil {
			return whole, nil
		}
		fraction, err := strconv.ParseFloat(text, 64)
		if err != nil {
			return nil, fmt.Errorf("%q is not a number", text)
		}
		return fraction, nil
	}
	return text, nil
}

func Shell(value any) (string, error) {
	text, ok := value.(string)
	if !ok {
		encoded, err := json.Marshal(value)
		if err != nil {
			return "", err
		}
		text = string(encoded)
	}
	return "'" + strings.ReplaceAll(text, "'", `'\''`) + "'", nil
}
