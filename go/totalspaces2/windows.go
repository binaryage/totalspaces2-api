// +build darwin,cgo

package totalspaces2

/*
#cgo CFLAGS: -x objective-c -I../../ruby/lib
#cgo LDFLAGS: -L../../ruby/lib -ltotalspaces2api
#include <TSLib.h>
*/
import "C"
import "unsafe"

type Windows struct {
	Count   uint
	Windows []Window
}

type Window struct {
	AppName       string
	ID            uint
	isOnAllSpaces bool
	Title         string
	Frame         string
	DisplayID     uint
	SpaceNumber   uint
}

func WindowList() []*Window {
	cWindows := windowList()
	defer freeWindowList(cWindows)

	wCount := int(cWindows.windowCount)

	windowPtrSize := unsafe.Sizeof(*cWindows.windows)

	firstWindowPtr := uintptr(unsafe.Pointer(cWindows.windows))

	w := make([]*Window, wCount)
	for i := 0; i < wCount; i++ {
		cWin := (*C.struct_tsapi_window)(unsafe.Pointer(firstWindowPtr + windowPtrSize*uintptr(i)))
		w[i] = &Window{
			AppName:       C.GoString(cWin.appName),
			ID:            uint(cWin.windowId),
			isOnAllSpaces: bool(cWin.isOnAllSpaces),
			Title:         C.GoString(cWin.title),
			Frame:         C.GoString(cWin.frame),
			DisplayID:     uint(cWin.displayID),
			SpaceNumber:   uint(cWin.spaceNumber),
		}
	}
	return w
}

func windowList() *C.struct_tsapi_windows {
	return C.tsapi_windowList()
}

func freeWindowList(windows *C.struct_tsapi_windows) {
	C.tsapi_freeWindowList(windows)
}
