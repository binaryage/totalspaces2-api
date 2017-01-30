// +build darwin,cgo

package totalspaces2

//#include <TSLib.h>
import "C"
import "unsafe"

type Display struct {
	ID     uint
	Name   string
	Width  uint
	Height uint
}

// DisplayList returns an array of hashes with information about
// attached displays. The ids returned from this call can be used
// where a display id is required in the other calls in this library.
func DisplayList() []*Display {
	cDisplays := displayList()
	defer freeDisplayList(cDisplays)

	dCount := int(cDisplays.displaysCount)

	// Each item in the c struct is displayPtrSize bytes
	displayPtrSize := unsafe.Sizeof(*cDisplays.displays)

	// Here's where the first one lives
	firstDisplayPtr := uintptr(unsafe.Pointer(cDisplays.displays))

	d := make([]*Display, dCount)

	for i := 0; i < dCount; i++ {
		cDisp := (*C.struct_tsapi_display)(unsafe.Pointer(firstDisplayPtr + displayPtrSize*uintptr(i)))
		d[i] = &Display{
			ID:     uint(cDisp.displayId),
			Name:   C.GoString(cDisp.displayName),
			Width:  uint(cDisp.width),
			Height: uint(cDisp.height),
		}
	}
	return d
}

func displayList() *C.struct_tsapi_displays {
	return C.tsapi_displayList()
}

func freeDisplayList(displays *C.struct_tsapi_displays) {
	C.tsapi_freeDisplayList(displays)
}
