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

func TestAValueThatIsNotAStringIsRenderedAsTheJSONItIs(t *testing.T) {
	for value, want := range map[any]string{
		float64(120): "'120'",
		true:         "'true'",
		false:        "'false'",
	} {
		quoted, err := assignable(value)
		if err != nil {
			t.Fatal(err)
		}
		if quoted != want {
			t.Errorf("%v was rendered as %s, not %s", value, quoted, want)
		}
	}
}
