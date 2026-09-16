package main

import "testing"

func TestAValueCannotEscapeTheAssignmentItIsPutIn(t *testing.T) {
	escaping := "'; touch /tmp/escaped; '"
	quoted, err := assignable(escaping)
	if err != nil {
		t.Fatal(err)
	}
	if quoted != `''\''; touch /tmp/escaped; '\'''` {
		t.Errorf("a value carrying a quote was rendered as %s", quoted)
	}
}

func TestANumberIsRenderedAsTheJSONItIs(t *testing.T) {
	quoted, err := assignable(float64(120))
	if err != nil {
		t.Fatal(err)
	}
	if quoted != "'120'" {
		t.Errorf("120 was rendered as %s, not '120'", quoted)
	}
}

func TestTrueIsRenderedAsTheJSONItIs(t *testing.T) {
	quoted, err := assignable(true)
	if err != nil {
		t.Fatal(err)
	}
	if quoted != "'true'" {
		t.Errorf("true was rendered as %s, not 'true'", quoted)
	}
}

func TestFalseIsRenderedAsTheJSONItIs(t *testing.T) {
	quoted, err := assignable(false)
	if err != nil {
		t.Fatal(err)
	}
	if quoted != "'false'" {
		t.Errorf("false was rendered as %s, not 'false'", quoted)
	}
}
