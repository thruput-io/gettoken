package contract_test

import (
	"strings"
	"testing"

	"github.com/thruput-io/gettoken/components/contract"
)

const contracts = "../../contracts"

func open(t *testing.T, name string) contract.Contract {
	t.Helper()
	governing, err := contract.Open(contracts, name)
	if err != nil {
		t.Fatalf("Open(%s): %v", name, err)
	}
	return governing
}

func TestNamingAContractThatIsNotThereSaysSo(t *testing.T) {
	_, err := contract.Open(contracts, "no-such-contract.schema.json")
	if err == nil {
		t.Fatal("a contract that is not there was opened")
	}
	if !strings.Contains(err.Error(), "no contract named no-such-contract.schema.json") {
		t.Errorf("the failure does not name the contract: %v", err)
	}
}

func TestAContractThatIsNotASchemaIsNotReportedAsMissing(t *testing.T) {
	_, err := contract.Open(".", "contract.go")
	if err == nil {
		t.Fatal("a file that is not a schema was opened as a contract")
	}
	if strings.Contains(err.Error(), "no contract named") {
		t.Errorf("an unreadable contract is reported as a missing one: %v", err)
	}
}

func TestADocumentItsContractAdmitsAnswersByKey(t *testing.T) {
	governing := open(t, "secret-put-request.schema.json")
	document, err := governing.Hold([]byte(`{"holder":"johans-laptop","service":"github","version":1}`))
	if err != nil {
		t.Fatalf("a document the contract admits was refused: %v", err)
	}
	holder, carried := document.Value("holder")
	if !carried || holder != "johans-laptop" {
		t.Errorf("holder answered (%v, %v)", holder, carried)
	}
}

func TestAFieldTheDocumentDoesNotCarryIsToldApartFromOneItDoes(t *testing.T) {
	governing := open(t, "secret-get-request.schema.json")
	document, err := governing.Hold([]byte(`{"holder":"johans-laptop","service":"github"}`))
	if err != nil {
		t.Fatal(err)
	}
	if _, carried := document.Value("version"); carried {
		t.Error("a field the document does not carry answered as carried")
	}
	if _, carried := document.Value("holder"); !carried {
		t.Error("a field the document carries answered as absent")
	}
}

func TestADocumentTheContractRefusesYieldsNothingToRead(t *testing.T) {
	governing := open(t, "secret-put-request.schema.json")
	document, err := governing.Hold([]byte(`{"holder":"johans-laptop"}`))
	if err == nil {
		t.Fatal("a document missing a required field was held")
	}
	if document != nil {
		t.Error("a refused document was still handed back")
	}
	if !strings.Contains(err.Error(), "does not satisfy secret-put-request.schema.json") {
		t.Errorf("the failure does not name the contract: %v", err)
	}
}

func TestABodyThatIsNotJSONIsRefusedRatherThanReadAsEmpty(t *testing.T) {
	governing := open(t, "secret-put-request.schema.json")
	if _, err := governing.Hold([]byte("not json")); err == nil {
		t.Fatal("a body that is not JSON was held")
	}
	if _, err := governing.Hold(nil); err == nil {
		t.Fatal("an empty body was held")
	}
}

func TestBuildChecksBeforeItYieldsADocument(t *testing.T) {
	governing := open(t, "secret-get-response.schema.json")
	if _, err := governing.Build(map[string]any{"found": false, "version": 1.0, "value": "leaked"}); err == nil {
		t.Fatal("a document the contract forbids was built")
	}
	document, err := governing.Build(map[string]any{"found": true, "version": 1.0, "value": "super-1"})
	if err != nil {
		t.Fatalf("a document the contract admits was refused: %v", err)
	}
	if value, _ := document.Value("value"); value != "super-1" {
		t.Errorf("value answered %v", value)
	}
}

func TestADocumentCannotBeChangedThroughWhatBuiltItOrWhatItAnswers(t *testing.T) {
	governing := open(t, "secret-get-response.schema.json")
	values := map[string]any{"found": true, "version": 1.0, "value": "super-1"}
	document, err := governing.Build(values)
	if err != nil {
		t.Fatal(err)
	}

	values["value"] = "swapped"
	if value, _ := document.Value("value"); value != "super-1" {
		t.Errorf("changing the map it was built from changed the document: %v", value)
	}

	encoded := document.JSON()
	for i := range encoded {
		encoded[i] = 'x'
	}
	if again := document.JSON(); string(again) == string(encoded) {
		t.Error("changing what JSON answered changed the document")
	}
	if !strings.Contains(string(document.JSON()), "super-1") {
		t.Errorf("the document no longer reads as it was admitted: %s", document.JSON())
	}
}
