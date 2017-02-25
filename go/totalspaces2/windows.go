// +build darwin,cgo

package totalspaces2

//#include <TSLib.h>
import "C"
import "unsafe"

type Windows struct {
	Count   uint
	Windows []Window
}

type Window struct {
	AppName       string
	ID            uint
	IsOnAllSpaces bool
	Title         string
	Frame         string
	DisplayID     uint
	SpaceNumber   uint
}

// WindowList gets a list of all the windows on your mac.

// It returns an array containing Window for each window. The windows
// are in front to back order within each space.
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
			IsOnAllSpaces: bool(cWin.isOnAllSpaces),
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
