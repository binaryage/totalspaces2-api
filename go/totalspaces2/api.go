// +build darwin,cgo

package totalspaces2

/*
#cgo CFLAGS: -x objective-c -I../../ruby/lib
#cgo LDFLAGS: -L../../ruby/lib -ltotalspaces2api
#include <TSLib.h>
#include <stdlib.h>
*/
import "C"

type SpaceType int

const (
	SpaceTypeDesktop SpaceType = iota
	SpaceTypeFullScreen
	SpaceTypeDashboard
)

func ApiVersion() string {
	return stringAndFree(C.tsapi_apiVersion())
}

func TotalSpacesVersion() string {
	return stringAndFree(C.tsapi_totalSpacesVersion())
}

func LibTotalSpacesVersion() string {
	return stringAndFree(C.tsapi_libTotalSpacesVersion())
}

func Enabled() bool {
	return ApiVersion() == LibTotalSpacesVersion()
}

func stringAndFree(ptr *C.char) string {
	str := C.GoString(ptr)
	C.tsapi_freeString(ptr)
	return str
}

func CurrentSpaceNumberOnDisplay(displayID uint) uint {
	return uint(C.tsapi_currentSpaceNumberOnDisplay(C.CGDirectDisplayID(displayID)))
}

func SpaceNameForSpaceNumberOnDisplay(space uint, display uint) string {
	return stringAndFree(
		C.tsapi_spaceNameForSpaceNumberOnDisplay(
			C.uint(space),
			C.CGDirectDisplayID(display)))
}

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

func UUIDForSpaceNumberOnDisplay(space uint, display uint) string {
	return stringAndFree(
		C.tsapi_uuidForSpaceNumberOnDisplay(
			C.uint(space),
			C.CGDirectDisplayID(display)))
}

func NumberOfSpacesOnDisplay(display uint) uint {
	return uint(
		C.tsapi_numberOfSpacesOnDisplay(
			C.CGDirectDisplayID(display)))
}

func DefinedColumnsOnDisplay(display uint) uint {
	return uint(
		C.tsapi_definedColumnsOnDisplay(
			C.CGDirectDisplayID(display)))
}

func SetDefinedColumnsOnDisplay(columns uint, display uint) bool {
	return bool(
		C.tsapi_setDefinedColumnsOnDisplay(
			C.uint(columns),
			C.CGDirectDisplayID(display)))
}

func MoveToSpaceOnDisplay(space uint, display uint) bool {
	return bool(
		C.tsapi_moveToSpaceOnDisplay(
			C.uint(space),
			C.CGDirectDisplayID(display)))
}

func SetNameForSpaceOnDisplay(space uint, name string, display uint) bool {
	str := C.CString(name)
	defer C.free(str)

	return bool(
		C.tsapi_setNameForSpaceOnDisplay(
			C.uint(space),
			str,
			C.CGDirectDisplayID(display)))
}

func MoveWindowToSpaceOnDisplay(window uint, space uint, display uint) bool {
	return bool(
		C.tsapi_moveWindowToSpaceOnDisplay(
			C.uint(window),
			C.uint(space),
			C.CGDirectDisplayID(display)))
}

func MoveSpaceToPositionOnDisplay(space uint, position uint, display uint) bool {
	return bool(
		C.tsapi_moveSpaceToPositionOnDisplay(
			C.uint(space),
			C.uint(position),
			C.CGDirectDisplayID(display)))
}

func MoveSpaceOnDisplayToPositionOnDisplay(space uint, fromDisplay uint, position uint, toDisplay uint) bool {
	return bool(
		C.tsapi_moveSpaceOnDisplayToPositionOnDisplay(
			C.uint(space),
			C.CGDirectDisplayID(fromDisplay),
			C.uint(position),
			C.CGDirectDisplayID(toDisplay)))
}

func AddDesktopsOnDisplay(numberToAdd uint, display uint) uint {
	return uint(
		C.tsapi_addDesktopsOnDisplay(C.uint(numberToAdd), C.CGDirectDisplayID(display)))
}

func RemoveDesktopsOnDisplay(numberToRemove uint, display C.CGDirectDisplayID) bool {
	return bool(
		C.tsapi_removeDesktopsOnDisplay(C.uint(numberToRemove), C.CGDirectDisplayID(display)))
}

func SetFrontWindow(window uint) {
	C.tsapi_setFrontWindow(C.uint(window))
}

func MoveWindow(window uint, x float64, y float64) {
	C.tsapi_moveWindow(C.uint(window), C.float(x), C.float(y))
}

func BindAppToSpace(bundleId string, spaceUUID string) {
	cBundle := C.CString(bundleId)
	defer C.free(cBundle)

	cSpace := C.CString(spaceUUID)
	defer C.free(cSpace)
	C.tsapi_bindAppToSpace(
		cBundle,
		cSpace)
}
