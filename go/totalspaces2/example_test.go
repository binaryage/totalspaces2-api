package totalspaces2_test

import (
	"fmt"

	"github.com/binaryage/totalspaces2-api/go/totalspaces2"
)

// This example shows some basic things you can do
func Example_basic() {

	spaceChangeCallback := func(x uint, y uint, z uint) {
		fmt.Printf("Space Change: %v -> %v (%v)\n", x, y, z)
	}
	totalspaces2.SetSpaceWillChangeCallback(spaceChangeCallback)

	totalspaces2.MoveToSpaceOnDisplay(1, 0)

	currentSpace := totalspaces2.CurrentSpaceNumberOnDisplay(0)
	fmt.Printf("Current space number: %v\n", currentSpace)
	fmt.Printf("Current space is called: %v\n", totalspaces2.SpaceNameForSpaceNumberOnDisplay(currentSpace, 0))

	totalspaces2.SetNameForSpaceOnDisplay(1, "Home", 0)
}
