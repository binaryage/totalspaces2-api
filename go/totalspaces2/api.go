// +build darwin,cgo

package totalspaces2

/*
#cgo CFLAGS: -x objective-c -I../../ruby/lib
#cgo LDFLAGS: -L ${SRCDIR} -ltotalspaces2api
#include <TSLib.h>
*/
import "C"
import "unsafe"

type SpaceType int

const (
	SpaceTypeDesktop SpaceType = iota
	SpaceTypeFullScreen
	SpaceTypeDashboard
)

// ApiVersion returns the version of the api present in TotalSpaces2,
// a string such as "1.0.1" You should be using the same dylib major
// version number as that returned by the this call.
func ApiVersion() string {
	return stringAndFree(C.tsapi_apiVersion())
}

// TotalSpacesVersion returns the version of TotalSpaces2 running on
// the system, a string such as "2.0.12".
func TotalSpacesVersion() string {
	return stringAndFree(C.tsapi_totalSpacesVersion())
}

// LibTotalSpacesVersion returns the version of the dylib, a string
// such as "1.0.1". You should be using the same dylib major version
// number as that returned by the api_version call.
func LibTotalSpacesVersion() string {
	return stringAndFree(C.tsapi_libTotalSpacesVersion())
}

// Enabled compares LibTotalSpacesVersion to ApiVersion and returns
// true if they are equal.
func Enabled() bool {
	return ApiVersion() == LibTotalSpacesVersion()
}

// stringAndFree takes in a pointer to a C string, converts it to a Go
// string and then frees the C string in memory
func stringAndFree(ptr *C.char) string {
	str := C.GoString(ptr)
	C.tsapi_freeString(ptr)
	return str
}

// CurrentSpaceNumberOnDisplay returns the number of the current
// space. Numbering starts at 1.
func CurrentSpaceNumberOnDisplay(displayID uint) uint {
	return uint(C.tsapi_currentSpaceNumberOnDisplay(C.CGDirectDisplayID(displayID)))
}

// SpaceNameForSpaceNumberOnDisplay returns the name for a space. The
// returned string will be empty if the space number is not valid.
func SpaceNameForSpaceNumberOnDisplay(space uint, display uint) string {
	return stringAndFree(
		C.tsapi_spaceNameForSpaceNumberOnDisplay(
			C.uint(space),
			C.CGDirectDisplayID(display)))
}

// CustomNameForSpaceNumberOnDisplay returns the custom name for the
// given space number. If the space has no custom name set in,
// TotalSpaces2, NULL is returned.
func CustomNameForSpaceNumberOnDisplay(space uint, display uint) string {
	return stringAndFree(
		C.tsapi_customNameForSpaceNumberOnDisplay(
			C.uint(space),
			C.CGDirectDisplayID(display)))
}

func SpaceTypeForSpaceNumberOnDisplay(space uint, display uint) SpaceType {
	switch C.tsapi_spaceTypeForSpaceNumberOnDisplay(
		C.uint(space),
		C.CGDirectDisplayID(display)) {
	case C.SpaceTypeDesktop:
		return SpaceTypeDesktop
	case C.SpaceTypeFullScreen:
		return SpaceTypeFullScreen
	case C.SpaceTypeDashboard:
		return SpaceTypeDashboard
	}
	return SpaceTypeDesktop
}

// UUIDForSpaceNumberOnDisplay returns the uuid for a space. The
// returned string will be empty if the space number is not valid.
func UUIDForSpaceNumberOnDisplay(space uint, display uint) string {
	return stringAndFree(
		C.tsapi_uuidForSpaceNumberOnDisplay(
			C.uint(space),
			C.CGDirectDisplayID(display)))
}

// NumberOfSpacesOnDisplay returns the total number of spaces
// including fullscreens, dashboard (if it's a space).
func NumberOfSpacesOnDisplay(display uint) uint {
	return uint(
		C.tsapi_numberOfSpacesOnDisplay(
			C.CGDirectDisplayID(display)))
}

// DefinedColumnsOnDisplay returns the number of columns defined in
// TotalSpaces2
func DefinedColumnsOnDisplay(display uint) uint {
	return uint(
		C.tsapi_definedColumnsOnDisplay(
			C.CGDirectDisplayID(display)))
}

// SetDefinedColumnsOnDisplay Sets the number of columns defined in
// TotalSpaces2. This does not change the actual number of desktops
// present, you should call AddDesktopsOnDisplay or
// RemoveDesktopsOnDisplay as appropriate after changing the number of
// columns.
func SetDefinedColumnsOnDisplay(columns uint, display uint) bool {
	return bool(
		C.tsapi_setDefinedColumnsOnDisplay(
			C.uint(columns),
			C.CGDirectDisplayID(display)))
}

// MoveToSpaceOnDisplay commands TotalSpaces2 to switch to the given
// space number. Returns false if the space number was invalid.  The
// SpaceWillChange notification will be sent.
func MoveToSpaceOnDisplay(space uint, display uint) bool {
	return bool(
		C.tsapi_moveToSpaceOnDisplay(
			C.uint(space),
			C.CGDirectDisplayID(display)))
}

// SetNameForSpaceOnDisplay sets the name for a space. Note that using
// this command will cause a layout change notification to be sent if
// the new name was different from that previously set. The maximum
// length for a name is 255 bytes.
func SetNameForSpaceOnDisplay(space uint, name string, display uint) bool {
	str := C.CString(name)
	defer C.free(unsafe.Pointer(str))

	return bool(
		C.tsapi_setNameForSpaceOnDisplay(
			C.uint(space),
			str,
			C.CGDirectDisplayID(display)))
}

// MoveWindowToSpaceOnDisplay moves a window to a given space on a
// given display. The windowID parameter must be fetched using
// WindowList. Returns false if the spaceNumber or windowID is invalid.
func MoveWindowToSpaceOnDisplay(windowID uint, spaceNumber uint, displayID uint) bool {
	return bool(
		C.tsapi_moveWindowToSpaceOnDisplay(
			C.uint(windowID),
			C.uint(spaceNumber),
			C.CGDirectDisplayID(displayID)))
}

// MoveSpaceToPositionOnDisplay moves space to a new position in the
// grid. Spaces can only be moved within their own display. Returns
// false if the spaceNumber or positionNumber is not valid.
func MoveSpaceToPositionOnDisplay(spaceNumber uint, positionNumber uint, displayID uint) bool {
	return bool(
		C.tsapi_moveSpaceToPositionOnDisplay(
			C.uint(spaceNumber),
			C.uint(positionNumber),
			C.CGDirectDisplayID(displayID)))
}

// MoveSpaceOnDisplayToPositionOnDisplay moves space to a new position
// on another screen. This won't work if you do not have displays have
// separate spaces enabled. Returns false if any parameters are not
// valid.
func MoveSpaceOnDisplayToPositionOnDisplay(space uint, fromDisplay uint, position uint, toDisplay uint) bool {
	return bool(
		C.tsapi_moveSpaceOnDisplayToPositionOnDisplay(
			C.uint(space),
			C.CGDirectDisplayID(fromDisplay),
			C.uint(position),
			C.CGDirectDisplayID(toDisplay)))
}

// AddDesktopsOnDisplay will add desktops on the specified
// display. There can be at most 16 desktops unless the display has
// collected some when a secondary display has been unplugged. Returns
// true on success, false if number_to_add was zero, or would result
// in more than 16 desktops. The on_layout_change notification will be
// sent if a changed was made.
func AddDesktopsOnDisplay(numberToAdd uint, display uint) uint {
	return uint(
		C.tsapi_addDesktopsOnDisplay(C.uint(numberToAdd), C.CGDirectDisplayID(display)))
}

// RemoveDesktopsOnDisplay will remove the highest numbered
// desktops. Removing a desktop you are currently on will result in
// TotalSpaces2 switching to another dektop. Any windows present on a
// desktop being removed will be moved to one of the remaining
// desktops. Returns true on success, false if number_to_remove was
// zero or would result in less than 1 desktop remaining.
func RemoveDesktopsOnDisplay(numberToRemove uint, display C.CGDirectDisplayID) bool {
	return bool(
		C.tsapi_removeDesktopsOnDisplay(C.uint(numberToRemove), C.CGDirectDisplayID(display)))
}

// SetFrontWindow moves a particular window to the front and activate
// it. This might be usful after moving windows to other desktops.
func SetFrontWindow(window uint) {
	C.tsapi_setFrontWindow(C.uint(window))
}

// MoveWindow moves a particular window to a new position.  Use the
// origin from the frame given by window_list as the starting point to
// make adustments. There is no validation, you can place a window far
// off the screen if you wish.
//
// For instance, if the frame or window id 123 is "{{146, 23}, {1133,
// 754}}", the origin is (146, 23). To move the window down 20 pixels,
// you would do this:
func MoveWindow(window uint, x float64, y float64) {
	C.tsapi_moveWindow(C.uint(window), C.float(x), C.float(y))
}

// BindAppToSpace binds an app to a space.  The bundle_id is normally
// in the format "com.apple.mail" Setting the space_uuid to AllSpaces
// will result in an app appearing on every desktop.  Setting the
// space_uuid to nil will delete the setting for the given bundle_id.
func BindAppToSpace(bundleId string, spaceUUID string) {
	cBundle := C.CString(bundleId)
	defer C.free(unsafe.Pointer(cBundle))

	cSpace := C.CString(spaceUUID)
	defer C.free(unsafe.Pointer(cSpace))
	C.tsapi_bindAppToSpace(
		cBundle,
		cSpace)
}
