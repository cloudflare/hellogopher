package main

import (
	"fmt"

	"example.com/hellogopher/subdirs/greetings"
)

// Version and BuildTime are filled in during build by the Makefile
var (
	Version   = "N/A"
	BuildTime = "N/A"
)

func main() {
	fmt.Println(greetings.Hello())
	fmt.Printf("Version: %s, BuildTime: %s\n", Version, BuildTime)
}
