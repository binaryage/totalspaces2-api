// +build darwin,cgo

package totalspaces2

/*
#include <TSLib.h>

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

//  SetSpaceWillChangeCallback registers for notifications on space change.
//
// The given function will be called whenever you move from one space to
// another. The arguments are the space number you moved from, and the
// one you are moving to.
//
// There can only be one block registered at any time, the most
// recently registered one will be called.  This callback is called
// just before the space actually changes - current_space will still
// report the from space.
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

// UnsetSpaceWillChangeCallback will cancel the onSpaceChange
// notification.
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

// SetLayoutChangedCallback registers for notifications on layout change.
//
// The given block will be called whenever the layout changes - this
// could be due to making an app fullscreen, changing a space name, or
// changing the layout of the TotalSpaces2 grid. There are no
// arguments passed to the block.
//
// When you get a notification from this method, you should re-fetch
// any information about the spaces that you may be storing.
//
// There can only be one function registered at any time, the most
// recently registered one will be called.
func SetLayoutChangedCallback(callback SpaceLayoutChangedCallback) {
	mu.Lock()
	defer mu.Unlock()
	spaceLayoutChangedCallback = callback
	C.tsapi_setLayoutChangedCallback((C.space_layout_changed_callback_t)(unsafe.Pointer(C.goSpaceLayoutChangedCallback)))
}

// UnsetLayoutChangedCallback cancel the layout change notification
func UnsetLayoutChangedCallback() {
	C.tsapi_unsetLayoutChangedCallback()
}
