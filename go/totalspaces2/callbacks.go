// +build darwin,cgo

package totalspaces2

/*
#cgo CFLAGS: -x objective-c -I../../ruby/lib
#cgo LDFLAGS: -L../../ruby/lib -ltotalspaces2api
#include <TSLib.h>
#include <stdlib.h>

// static inlining
extern void goSpaceChangeCallback(unsigned int from, unsigned int to, CGDirectDisplayID display);
extern void goSpaceLayoutChangedCallback();

// Forward declarations
void goSpaceChangeCallback_cgo(unsigned int from, unsigned int to, CGDirectDisplayID displayID);
void goSpaceLayoutChangedCallback_cgo();

*/
import "C"
import (
	"sync"
	"unsafe"
)

type SpaceChangeCallback func(uint, uint, uint)
type SpaceLayoutChangedCallback func()

var mu sync.Mutex
var spaceChangeCallback SpaceChangeCallback
var spaceLayoutChangedCallback SpaceLayoutChangedCallback

//export goSpaceChangeCallback
func goSpaceChangeCallback(from C.uint, to C.uint, display C.CGDirectDisplayID) {
	if spaceChangeCallback == nil {
		C.tsapi_unsetSpaceWillChangeCallback()
		return
	}
	spaceChangeCallback(
		uint(from),
		uint(to),
		uint(display),
	)
}

func SetSpaceWillChangeCallback(callback SpaceChangeCallback) {
	mu.Lock()
	defer mu.Unlock()
	spaceChangeCallback = func(fromSpace uint, toSpace uint, display uint) {
		callback(
			uint(fromSpace),
			uint(toSpace),
			uint(display),
		)
	}

	C.tsapi_setSpaceWillChangeCallback((C.space_change_callback_t)(unsafe.Pointer(C.goSpaceChangeCallback_cgo)))

}

func UnsetSpaceWillChangeCallback() {
	C.tsapi_unsetSpaceWillChangeCallback()
	spaceChangeCallback = nil
}

//export goSpaceLayoutChangedCallback
func goSpaceLayoutChangedCallback() {
	if spaceLayoutChangedCallback == nil {
		C.tsapi_unsetLayoutChangedCallback()
		spaceLayoutChangedCallback = nil
	}
	spaceLayoutChangedCallback()
}

func SetLayoutChangedCallback(callback SpaceLayoutChangedCallback) {
	mu.Lock()
	defer mu.Unlock()
	spaceLayoutChangedCallback = callback
	C.tsapi_setLayoutChangedCallback((C.space_layout_changed_callback_t)(unsafe.Pointer(C.goSpaceLayoutChangedCallback)))
}

func UnsetLayoutChangedCallback() {
	C.tsapi_unsetLayoutChangedCallback()
}
