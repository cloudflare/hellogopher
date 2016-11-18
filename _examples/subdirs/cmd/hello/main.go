package main

import (
	"fmt"

	"example.com/hellogopher/subdirs/greetings"
)

var ( // filled in at build time by the Makefile
	Version   = "N/A"
	BuildTime = "N/A"
)

func main() {
	fmt.Println(greetings.Hello())
	fmt.Printf("Version: %s, BuildTime: %s\n", Version, BuildTime)
}
