package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const contracts = "../../../../contracts"

// answering writes a component that answers the way the test needs, and hands
// back the path a door would name with --answers.
func answering(t *testing.T, said string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "example.answers")
	if err := os.WriteFile(path, []byte("#!/bin/sh\nset -eu\n"+said+"\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	return path
}

// serving reaches a door the way a caller does, and reports what the caller saw.
func serving(t *testing.T, args ...string) (int, string, string) {
	t.Helper()
	t.Setenv("CONTRACTS_DIR", contracts)
	out, complaints := bytes.Buffer{}, bytes.Buffer{}
	status := run(args, strings.NewReader(""), &out, &complaints)
	return status, out.String(), complaints.String()
}

func storing(t *testing.T) []string {
	t.Helper()
	return []string{
		"--request", "secret-put-request.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", answering(t, `cat > /dev/null; printf '%s\n' '{"version":0,"value":"super-1"}'`),
		"--",
	}
}

func TestAPayloadGivenAsAnArgumentIsAnsweredOnStandardOutput(t *testing.T) {
	status, out, complaints := serving(t, append(storing(t), `{"key":"johans-laptop/github","value":"super-1"}`)...)
	if status != 0 {
		t.Fatalf("a payload the contract admits was refused: %s", complaints)
	}
	if out != `{"version":0,"value":"super-1"}`+"\n" {
		t.Errorf("the answer came back as %q", out)
	}
}

func TestThePayloadReachesWhatAnswers(t *testing.T) {
	seen := filepath.Join(t.TempDir(), "seen")
	t.Setenv("SEEN", seen)
	door := []string{
		"--request", "secret-put-request.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", answering(t, `cat > "$SEEN"; printf '%s\n' '{"version":0,"value":"super-1"}'`),
		"--", `{"key":"johans-laptop/github","value":"super-1"}`,
	}
	if status, _, complaints := serving(t, door...); status != 0 {
		t.Fatalf("status %d: %s", status, complaints)
	}
	read, err := os.ReadFile(seen)
	if err != nil {
		t.Fatal(err)
	}
	if string(read) != `{"key":"johans-laptop/github","value":"super-1"}` {
		t.Errorf("what answers was handed %q", read)
	}
}

func TestStandardInputIsWhereTheAskComesFromWhenTheCallerSaysSo(t *testing.T) {
	t.Setenv("CONTRACTS_DIR", contracts)
	out, complaints := bytes.Buffer{}, bytes.Buffer{}
	args := append(storing(t), "--stdin")
	status := run(args, strings.NewReader(`{"key":"johans-laptop/github","value":"super-1"}`), &out, &complaints)
	if status != 0 {
		t.Fatalf("an ask on standard input was refused: %s", complaints.String())
	}
	if out.String() != `{"version":0,"value":"super-1"}`+"\n" {
		t.Errorf("the answer came back as %q", out.String())
	}
}

func TestAFileTheCallerNamesTakesTheAnswerInsteadOfStandardOutput(t *testing.T) {
	into := filepath.Join(t.TempDir(), "answer.json")
	args := append(storing(t), "-f", into, `{"key":"johans-laptop/github","value":"super-1"}`)
	status, out, complaints := serving(t, args...)
	if status != 0 {
		t.Fatalf("status %d: %s", status, complaints)
	}
	if out != "" {
		t.Errorf("the answer was also written to standard output: %q", out)
	}
	written, err := os.ReadFile(into)
	if err != nil {
		t.Fatal(err)
	}
	if string(written) != `{"version":0,"value":"super-1"}`+"\n" {
		t.Errorf("the file holds %q", written)
	}
}

func TestAFileTheAnswerIsWrittenToIsClosedToEveryoneButItsOwner(t *testing.T) {
	into := filepath.Join(t.TempDir(), "answer.json")
	if err := os.WriteFile(into, []byte("older"), 0o644); err != nil {
		t.Fatal(err)
	}
	args := append(storing(t), "-f", into, `{"key":"johans-laptop/github","value":"super-1"}`)
	if status, _, complaints := serving(t, args...); status != 0 {
		t.Fatalf("status %d: %s", status, complaints)
	}
	how, err := os.Stat(into)
	if err != nil {
		t.Fatal(err)
	}
	if how.Mode().Perm() != 0o600 {
		t.Errorf("a file that was open to everyone was left at %v", how.Mode().Perm())
	}
}

func TestAnAskNoContractAdmitsNeverReachesWhatAnswers(t *testing.T) {
	ran := filepath.Join(t.TempDir(), "ran")
	t.Setenv("RAN", ran)
	door := []string{
		"--request", "secret-put-request.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", answering(t, `touch "$RAN"; printf '%s\n' '{"version":0,"value":"super-1"}'`),
		"--", `{"key":"Johans-Laptop","value":"super-1"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 1 {
		t.Fatalf("an ask the contract refuses left with status %d", status)
	}
	if out != "" {
		t.Errorf("something was handed over: %q", out)
	}
	if !strings.Contains(complaints, "does not satisfy secret-put-request.schema.json") {
		t.Errorf("the refusal does not name the contract: %s", complaints)
	}
	if _, err := os.Stat(ran); err == nil {
		t.Error("what answers was run with an ask its contract refuses")
	}
}

func TestAnAnswerTheContractRefusesIsNotHandedOver(t *testing.T) {
	door := []string{
		"--request", "secret-put-request.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", answering(t, `cat > /dev/null; printf '%s\n' '{"version":0}'`),
		"--", `{"key":"johans-laptop/github","value":"super-1"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 1 {
		t.Fatalf("an answer the contract refuses left with status %d", status)
	}
	if out != "" {
		t.Errorf("an answer no contract admitted was handed over: %q", out)
	}
	if !strings.Contains(complaints, "does not satisfy secret-put-response.schema.json") {
		t.Errorf("the refusal does not name the contract: %s", complaints)
	}
}

func TestTheOneFieldADoorHandsOverIsWrittenAsTextAndNothingElseIs(t *testing.T) {
	door := []string{
		"--request", "exchange-request.schema.json",
		"--response", "token-response.schema.json",
		"--field", "access_token",
		"--answers", answering(t, `cat > /dev/null; printf '%s\n' '{"access_token":"narrow-token","expires_in":120}'`),
		"--", `{"who":"tore","wants":"integrationtest/ci/run"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 0 {
		t.Fatalf("status %d: %s", status, complaints)
	}
	if out != "narrow-token\n" {
		t.Errorf("the caller was handed %q", out)
	}
}

func TestAFieldThatIsNotTextIsHandedOverAsTheJSONItIs(t *testing.T) {
	door := []string{
		"--request", "exchange-request.schema.json",
		"--response", "token-response.schema.json",
		"--field", "expires_in",
		"--answers", answering(t, `cat > /dev/null; printf '%s\n' '{"access_token":"narrow-token","expires_in":120}'`),
		"--", `{"who":"tore","wants":"integrationtest/ci/run"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 0 {
		t.Fatalf("status %d: %s", status, complaints)
	}
	if out != "120\n" {
		t.Errorf("the caller was handed %q", out)
	}
}

func TestADoorTakingMoreThanOneShapeTellsWhatAnswersWhichOneItWas(t *testing.T) {
	door := func(ask string) []string {
		return []string{
			"--request", "secret-get-request.schema.json",
			"--request", "secret-get-request-version.schema.json",
			"--response", "secret-get-response.schema.json",
			"--answers", answering(t, `cat > /dev/null; printf '{"version":0,"value":"%s"}\n' "$REQUEST_CONTRACT"`),
			"--", ask,
		}
	}
	status, out, complaints := serving(t, door(`{"key":"johans-laptop/github"}`)...)
	if status != 0 {
		t.Fatalf("status %d: %s", status, complaints)
	}
	if !strings.Contains(out, "secret-get-request.schema.json") {
		t.Errorf("what answers was told %q", out)
	}
	status, out, complaints = serving(t, door(`{"key":"johans-laptop/github","version":0}`)...)
	if status != 0 {
		t.Fatalf("status %d: %s", status, complaints)
	}
	if !strings.Contains(out, "secret-get-request-version.schema.json") {
		t.Errorf("what answers was told %q", out)
	}
}

func TestTwoShapesAdmittingTheSameAskIsRefusedRatherThanGuessed(t *testing.T) {
	door := []string{
		"--request", "secret-put-request.schema.json",
		"--request", "secret-put-request.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", answering(t, `cat > /dev/null; printf '%s\n' '{"version":0,"value":"super-1"}'`),
		"--", `{"key":"johans-laptop/github","value":"super-1"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 1 {
		t.Fatalf("an ask two shapes admit left with status %d", status)
	}
	if out != "" {
		t.Errorf("something was handed over: %q", out)
	}
	if !strings.Contains(complaints, "both admit") {
		t.Errorf("the refusal does not say why: %s", complaints)
	}
}

func TestWhatAnswersTakesTheCallerDownWithItsOwnStatus(t *testing.T) {
	door := []string{
		"--request", "secret-put-request.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", answering(t, `cat > /dev/null; echo "example: no" >&2; exit 3`),
		"--", `{"key":"johans-laptop/github","value":"super-1"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 3 {
		t.Fatalf("what answers failed with 3 and the door left with %d", status)
	}
	if out != "" {
		t.Errorf("something was handed over: %q", out)
	}
	if complaints != "example: no\n" {
		t.Errorf("the door spoke over what answers, or swallowed it: %q", complaints)
	}
}

func TestADoorWithNothingBehindItSaysSo(t *testing.T) {
	door := []string{
		"--request", "secret-put-request.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", filepath.Join(t.TempDir(), "nothing.answers"),
		"--", `{"key":"johans-laptop/github","value":"super-1"}`,
	}
	status, _, complaints := serving(t, door...)
	if status != 1 {
		t.Fatalf("a door with nothing behind it left with status %d", status)
	}
	if !strings.Contains(complaints, "nothing answers at") {
		t.Errorf("the failure does not say what is missing: %s", complaints)
	}
}

func TestACallerSayingNothingIsToldHowToSayIt(t *testing.T) {
	status, out, complaints := serving(t, storing(t)...)
	if status != 1 {
		t.Fatalf("a caller that said nothing left with status %d", status)
	}
	if out != "" {
		t.Errorf("something was handed over: %q", out)
	}
	if !strings.Contains(complaints, "usage: example [-f FILE] (PAYLOAD | --stdin)") {
		t.Errorf("the caller was not told how to ask: %s", complaints)
	}
}

func TestACallerCannotBothNameAnAskAndPointAtStandardInput(t *testing.T) {
	args := append(storing(t), "--stdin", `{"key":"johans-laptop/github","value":"super-1"}`)
	status, _, complaints := serving(t, args...)
	if status != 1 {
		t.Fatalf("an ask said twice over left with status %d", status)
	}
	if !strings.Contains(complaints, "usage:") {
		t.Errorf("the caller was not told how to ask: %s", complaints)
	}
}

func TestACallerNamingNoFileToWriteToIsToldHowToAsk(t *testing.T) {
	args := append(storing(t), `{"key":"johans-laptop/github","value":"super-1"}`, "-f")
	status, _, complaints := serving(t, args...)
	if status != 1 {
		t.Fatalf("a -f naming nothing left with status %d", status)
	}
	if !strings.Contains(complaints, "usage:") {
		t.Errorf("the caller was not told how to ask: %s", complaints)
	}
}

func TestACallerSayingTheSameThingTwiceIsToldHowToAsk(t *testing.T) {
	args := append(storing(t), `{"key":"johans-laptop/github","value":"super-1"}`, `{"key":"other/github","value":"super-2"}`)
	status, _, complaints := serving(t, args...)
	if status != 1 {
		t.Fatalf("two asks at once left with status %d", status)
	}
	if !strings.Contains(complaints, "usage:") {
		t.Errorf("the caller was not told how to ask: %s", complaints)
	}
}

func TestWhatACallerSaysCannotDescribeTheDoor(t *testing.T) {
	ran := filepath.Join(t.TempDir(), "ran")
	t.Setenv("RAN", ran)
	door := []string{
		"--request", "secret-put-request.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", answering(t, `touch "$RAN"; printf '%s\n' '{"version":0,"value":"super-1"}'`),
		"--", "--answers", "/bin/sh",
	}
	status, out, _ := serving(t, door...)
	if status == 0 {
		t.Fatal("a caller describing the door was served")
	}
	if out != "" {
		t.Errorf("something was handed over: %q", out)
	}
	if _, err := os.Stat(ran); err == nil {
		t.Error("what answers was run for an ask no contract admitted")
	}
}

func TestADoorDescribedWithSomethingItIsNotSaysSo(t *testing.T) {
	door := []string{"--listen", ":8080", "--", `{"key":"johans-laptop/github","value":"super-1"}`}
	status, _, complaints := serving(t, door...)
	if status != 1 {
		t.Fatalf("a door described with something it is not left with status %d", status)
	}
	if !strings.Contains(complaints, "not something a door is described with") {
		t.Errorf("the failure does not say what was wrong: %s", complaints)
	}
}

func TestEveryPartOfADoorIsNamedOrTheDoorIsNotOpened(t *testing.T) {
	missing := map[string][]string{
		"--request":  {"--response", "secret-put-response.schema.json", "--answers", "x.answers", "--"},
		"--response": {"--request", "secret-put-request.schema.json", "--answers", "x.answers", "--"},
		"--answers":  {"--request", "secret-put-request.schema.json", "--response", "secret-put-response.schema.json", "--"},
	}
	for named, door := range missing {
		status, _, complaints := serving(t, door...)
		if status != 1 {
			t.Errorf("a door with no %s left with status %d", named, status)
		}
		if !strings.Contains(complaints, "serve: ") {
			t.Errorf("a door with no %s did not say so: %s", named, complaints)
		}
	}
}

func TestAFlagNamingNothingIsNotReadAsTheNextOne(t *testing.T) {
	status, _, complaints := serving(t, "--request", "--")
	if status != 1 {
		t.Fatalf("a flag naming nothing left with status %d", status)
	}
	if !strings.Contains(complaints, "names nothing") {
		t.Errorf("the failure does not say what was wrong: %s", complaints)
	}
}

func TestADoorAndACallerAreToldApartByTheOneThingBetweenThem(t *testing.T) {
	status, _, complaints := serving(t, "--request", "secret-put-request.schema.json")
	if status != 1 {
		t.Fatalf("a call with no halves left with status %d", status)
	}
	if !strings.Contains(complaints, "described left of -- and reached right of it") {
		t.Errorf("the failure does not say how a call is made: %s", complaints)
	}
}

func TestAContractThatIsNotThereIsReportedAgainstTheDoorThatNamedIt(t *testing.T) {
	door := []string{
		"--request", "no-such-contract.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", answering(t, `cat > /dev/null`),
		"--", `{"key":"johans-laptop/github","value":"super-1"}`,
	}
	status, _, complaints := serving(t, door...)
	if status != 1 {
		t.Fatalf("a contract that is not there left with status %d", status)
	}
	if !strings.Contains(complaints, "no contract named no-such-contract.schema.json") {
		t.Errorf("the failure does not name the contract: %s", complaints)
	}
}

func TestAnAnswerGovernedByAContractThatIsNotThereIsNotHandedOver(t *testing.T) {
	door := []string{
		"--request", "secret-put-request.schema.json",
		"--response", "no-such-contract.schema.json",
		"--answers", answering(t, `cat > /dev/null; printf '%s\n' '{"version":0,"value":"super-1"}'`),
		"--", `{"key":"johans-laptop/github","value":"super-1"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 1 {
		t.Fatalf("an answer with no contract left with status %d", status)
	}
	if out != "" {
		t.Errorf("an answer nothing governs was handed over: %q", out)
	}
	if !strings.Contains(complaints, "no contract named no-such-contract.schema.json") {
		t.Errorf("the failure does not name the contract: %s", complaints)
	}
}

func TestAFieldTheAnswerDoesNotCarryIsNotGuessedAt(t *testing.T) {
	door := []string{
		"--request", "exchange-request.schema.json",
		"--response", "token-response.schema.json",
		"--field", "refresh_token",
		"--answers", answering(t, `cat > /dev/null; printf '%s\n' '{"access_token":"narrow-token","expires_in":120}'`),
		"--", `{"who":"tore","wants":"integrationtest/ci/run"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 1 {
		t.Fatalf("a field the answer does not carry left with status %d", status)
	}
	if out != "" {
		t.Errorf("something was handed over: %q", out)
	}
	if !strings.Contains(complaints, "carries no refresh_token") {
		t.Errorf("the failure does not name the field: %s", complaints)
	}
}

func TestAFileThatCannotBeWrittenIsAFailureRatherThanASilentOne(t *testing.T) {
	args := append(storing(t), "-f", filepath.Join(t.TempDir(), "nowhere", "answer.json"),
		`{"key":"johans-laptop/github","value":"super-1"}`)
	status, out, complaints := serving(t, args...)
	if status != 1 {
		t.Fatalf("a file that cannot be written left with status %d", status)
	}
	if out != "" {
		t.Errorf("the answer fell back to standard output: %q", out)
	}
	if !strings.Contains(complaints, "answer.json") {
		t.Errorf("the failure does not name the file: %s", complaints)
	}
}

func TestSomethingStoppedBeforeItAnsweredIsNotMistakenForAnAnswer(t *testing.T) {
	door := []string{
		"--request", "secret-put-request.schema.json",
		"--response", "secret-put-response.schema.json",
		"--answers", answering(t, `cat > /dev/null; kill -TERM $$`),
		"--", `{"key":"johans-laptop/github","value":"super-1"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 1 {
		t.Fatalf("something stopped before it answered left with status %d", status)
	}
	if out != "" {
		t.Errorf("something was handed over: %q", out)
	}
	if !strings.Contains(complaints, "stopped before it answered") {
		t.Errorf("the failure does not say what happened: %s", complaints)
	}
}

func TestACallerCannotDictateWhichShapeWhatAnswersIsTold(t *testing.T) {
	t.Setenv("REQUEST_CONTRACT", "token-request.schema.json")
	door := []string{
		"--request", "secret-get-request.schema.json",
		"--response", "secret-get-response.schema.json",
		"--answers", answering(t, `cat > /dev/null; printf '{"version":0,"value":"%s"}\n' "$REQUEST_CONTRACT"`),
		"--", `{"key":"johans-laptop/github"}`,
	}
	status, out, complaints := serving(t, door...)
	if status != 0 {
		t.Fatalf("status %d: %s", status, complaints)
	}
	if !strings.Contains(out, "secret-get-request.schema.json") {
		t.Errorf("what answers was told the caller's shape rather than the one that admitted: %q", out)
	}
}
