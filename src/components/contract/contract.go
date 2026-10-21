// Package contract holds JSON documents to the schemas that govern them.
//
// The schemas in contracts/ are the whole statement of what a document may
// carry. This package restates none of it: it names no field and knows no
// domain type. It reads a schema, hands a document to it, and reports what the
// schema said, and it reads the type a schema declares for a field so that
// text given for that field becomes a value of that type.
//
// A document therefore exists in one form only, the held form. Hold and Build
// both check before they return, so holding a Document is itself the proof that
// its contract admitted it — there is no unchecked document to pass on by
// mistake. A Document cannot be changed once made and answers only by key.
package contract

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"net/url"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/jsonschema-go/jsonschema"
)

const namespace = "https://thruput.io/gettoken/"

// A Contract is one schema, resolved against the directory it was read from.
// Open is the only way to obtain one.
type Contract interface {
	// Hold checks raw JSON against the contract and returns it as a Document.
	Hold(raw []byte) (Document, error)
	// Build checks an assembled set of values against the contract and returns
	// them as a Document. The values are copied, so the caller cannot reach
	// into the Document afterwards.
	Build(values map[string]any) (Document, error)
	// Typed reads text given for field as the type the contract declares for
	// it: a string field keeps the text as it is, any other field reads it as
	// JSON. Text that is not JSON is kept as text, for the contract to refuse.
	Typed(field, text string) (any, error)
}

// A Document is a JSON object that its contract has admitted. It cannot be
// changed, and the only thing it does is answer by key.
type Document interface {
	// Value answers the value carried under key, and whether the document
	// carries that key at all. A key present as JSON null answers (nil, true);
	// a key that is absent answers (nil, false).
	Value(key string) (any, bool)
	// JSON is the document as its contract admitted it.
	JSON() []byte
}

type held struct {
	name      string
	directory string
	resolved  *jsonschema.Resolved
}

type admitted struct {
	values map[string]any
	raw    []byte
}

// Directory is where the packages install the contracts, or where CONTRACTS_DIR
// names instead. Entry points call it and pass what it answers to Open, so that
// nothing below them reads the environment for itself.
func Directory() string {
	if named := os.Getenv("CONTRACTS_DIR"); named != "" {
		return named
	}
	return "@datadir@/gettoken/contracts"
}

func read(directory, name string) (*jsonschema.Schema, error) {
	raw, err := os.ReadFile(filepath.Join(directory, name))
	if err != nil {
		return nil, err
	}
	schema := new(jsonschema.Schema)
	if err := json.Unmarshal(raw, schema); err != nil {
		return nil, fmt.Errorf("contract %s is not a readable schema: %w", name, err)
	}
	return schema, nil
}

// Open reads the contract named by name from directory and resolves the
// references it makes to its neighbours there.
func Open(directory, name string) (Contract, error) {
	root, err := read(directory, name)
	if errors.Is(err, fs.ErrNotExist) {
		return nil, fmt.Errorf("no contract named %s in %s", name, directory)
	}
	if err != nil {
		return nil, err
	}
	resolved, err := root.Resolve(&jsonschema.ResolveOptions{
		BaseURI: namespace + name,
		Loader: func(reference *url.URL) (*jsonschema.Schema, error) {
			return read(directory, filepath.Base(reference.Path))
		},
	})
	if err != nil {
		return nil, fmt.Errorf("contract %s does not resolve: %w", name, err)
	}
	return held{name: name, directory: directory, resolved: resolved}, nil
}

func (h held) admit(document any, raw []byte) (Document, error) {
	if err := h.resolved.Validate(document); err != nil {
		return nil, fmt.Errorf("the document does not satisfy %s\n%w", h.name, err)
	}
	values, keyed := document.(map[string]any)
	if !keyed {
		return nil, fmt.Errorf("%s admitted a document that carries no fields to read by name", h.name)
	}
	carried := make(map[string]any, len(values))
	for key, value := range values {
		carried[key] = value
	}
	return admitted{values: carried, raw: raw}, nil
}

func (h held) Hold(raw []byte) (Document, error) {
	var document any
	if err := json.Unmarshal(raw, &document); err != nil {
		return nil, fmt.Errorf("the document is not JSON: %w", err)
	}
	return h.admit(document, raw)
}

func (h held) Build(values map[string]any) (Document, error) {
	document := make(map[string]any, len(values))
	for key, value := range values {
		document[key] = value
	}
	raw, err := json.Marshal(document)
	if err != nil {
		return nil, err
	}
	return h.admit(document, raw)
}

func (h held) declared(field string) (string, error) {
	property, governed := h.resolved.Schema().Properties[field]
	if !governed {
		return "", nil
	}
	if property.Ref == "" {
		return property.Type, nil
	}
	reference, err := url.Parse(property.Ref)
	if err != nil {
		return "", err
	}
	schema, err := read(h.directory, filepath.Base(reference.Path))
	if err != nil {
		return "", err
	}
	name := strings.TrimPrefix(reference.Fragment, "/$defs/")
	definition, defined := schema.Defs[name]
	if !defined {
		return "", fmt.Errorf("%s names %s for %s, which %s does not define", h.name, property.Ref, field, reference.Path)
	}
	return definition.Type, nil
}

func (h held) Typed(field, text string) (any, error) {
	declared, err := h.declared(field)
	if err != nil {
		return nil, err
	}
	if declared == "string" {
		return text, nil
	}
	var read any
	if err := json.Unmarshal([]byte(text), &read); err != nil {
		return text, nil
	}
	return read, nil
}

func (a admitted) Value(key string) (any, bool) {
	value, carried := a.values[key]
	return value, carried
}

func (a admitted) JSON() []byte {
	return append([]byte(nil), a.raw...)
}
