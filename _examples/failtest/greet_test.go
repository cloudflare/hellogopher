package greetings

import "testing"

func TestHello(t *testing.T) {
	if Hello() != "Hello, gopher!" {
		t.Fail()
	}
}
