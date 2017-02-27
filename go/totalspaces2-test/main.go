// +build darwin,cgo

package main

import (
	"flag"
	"fmt"
	"os"
	"os/signal"

	"github.com/binaryage/totalspaces2-api/go/totalspaces2"
)

func main() {
	if !totalspaces2.Enabled() {
		os.Exit(1)
	}

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)

	displayPtr := flag.Uint("display", 0, "display number")
	desktopPtr := flag.Uint("desktop", 1, "desktop number")
	flag.Parse()

	totalspaces2.MoveToSpaceOnDisplay(*desktopPtr, *displayPtr)

	displays := totalspaces2.DisplayList()
	for i, value := range displays {
		fmt.Printf("Display %v:\n", i)
		fmt.Printf("%#v\n", value)
	}

	name := totalspaces2.SpaceNameForSpaceNumberOnDisplay(1, displays[0].ID)
	fmt.Printf("Current Name of Display0, Space1: %v\n", name)

	totalspaces2.SetNameForSpaceOnDisplay(1, "Testing!", displays[0].ID)
	tmpName := totalspaces2.SpaceNameForSpaceNumberOnDisplay(1, displays[0].ID)
	fmt.Printf("Renamed Display0, Space1: %v\n", tmpName)

	windows := totalspaces2.WindowList()
	for i, value := range windows {
		fmt.Printf("Window %v:\n", i)
		fmt.Printf("%#v\n", value)
	}

	t := totalspaces2.SpaceTypeForSpaceNumberOnDisplay(1, 0)
	fmt.Printf("%v\n", t)

	f := func(x uint, y uint, z uint) {
		fmt.Printf("Space Change: %v -> %v (%v)\n", x, y, z)
	}
	totalspaces2.SetLayoutChangedCallback(func() {
		fmt.Println("Layout Change!")
	})
	totalspaces2.SetSpaceWillChangeCallback(f)
	totalspaces2.MoveToSpaceOnDisplay(2, 0)

	// Waiting for os.Signal
	_ = <-c
	totalspaces2.SetNameForSpaceOnDisplay(1, name, displays[0].ID)

}
