package greetings

import "testing"

func TestHello(t *testing.T) {
	if Hello() != "Hello, world!" {
		t.Fail()
	}
}
