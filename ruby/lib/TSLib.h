//
//  TSLib.h
//  totalspacesapi
//
//  Created by Stephen Sykes on 27/1/13.
//  Copyright (c) 2013 Stephen Sykes. All rights reserved.
//
//  The API is a premium feature, and will only work with registered versions of TotalSpaces.
//

#ifndef totalspacesapi_tslib_h
#define totalspacesapi_tslib_h

#import <Foundation/Foundation.h>

#define TSAPI_MAX_SPACES 32

/*
 * In case of comm error, all the functions apart from tsapi_libTotalSpacesVersion() will 
 * return an empty string, zero, false or a pointer to a struct containing zero spaces (in 
 * the case of tsapi_windowList).
 * It is recommended to check that comms to TotalSpaces are working by, for instance,
 * checking that tsapi_apiVersion() matches tsapi_libTotalSpacesVersion() when you initialize
 * your app.
 *
 * Some actions such as renaming a space will cause the overview grid to be exited if it
 * is showing at the time.
 */

/*
 * The version of the API present in TotalSpaces.app.
 *
 * You must call tsapi_freeString when you have finished with the returned string.
 */
const char *tsapi_apiVersion();

/*
 * The version number of TotalSpaces itself.
 *
 * You must call tsapi_freeString when you have finished with the returned string.
 */
const char *tsapi_totalSpacesVersion();

/*
 * The version of the API dylib. This should match the string returned
 * by tsapi_apiVersion().
 *
 * You must call tsapi_freeString when you have finished with the returned string.
 */
const char *tsapi_libTotalSpacesVersion();

/*
 * Struct containing info about a display.
 */
struct tsapi_display {
  CGDirectDisplayID displayId;
  char *displayName;
  size_t width;
  size_t height;
};

/*
 * Struct containing the count of spaces and a pointer to an
 * array of CGDirectDisplayIDs.
 */
struct tsapi_displays {
  unsigned int displaysCount;
  struct tsapi_display *displays;
};

/*
 * Return a pointer to a tsapi_displays struct containing information about all the displays.
 *
 * The first display in the list will be the main display. The main display is the display 
 * with its screen location at (0,0) in the global display coordinate space. In a system
 * without display mirroring, the display with the menu bar is typically the main display.
 *
 * You must call tsapi_freeDisplayList when you have finished with this.
 */
struct tsapi_displays *tsapi_displayList();

/*
 * Free a previously returned tsapi_displays struct
 */
void tsapi_freeDisplayList(struct tsapi_displays *displayList);

/*
 * The number of the current space.
 *
 * If the current space is the dashboard, 0 is returned.
 */
unsigned int tsapi_currentSpaceNumberOnDisplay(CGDirectDisplayID displayID);

/*
 * The name for the given space number.
 *
 * You must call tsapi_freeString when you have finished with the returned string.
 */
const char *tsapi_spaceNameForSpaceNumberOnDisplay(unsigned int spaceNumber, CGDirectDisplayID displayID);

/*
 * The uuid for the given space number. This uniquely identifies the space, even when
 * it is moved to a different position or to another monitor.
 *
 * You must call tsapi_freeString when you have finished with the returned string.
 */
const char *tsapi_uuidForSpaceNumberOnDisplay(unsigned int spaceNumber, CGDirectDisplayID displayID);

/*
 * The total number of spaces.
 * This includes the dashboard if you have it set as a space, and any
 * fullscreen apps.
 */
unsigned int tsapi_numberOfSpacesOnDisplay(CGDirectDisplayID displayID);

/*
 * The number of columns defined in TotalSpaces layout preferences.
 */
unsigned int tsapi_definedColumnsOnDisplay(CGDirectDisplayID displayID);

/*
 * Sets the number of columns in the TotalSpaces grid.
 * Returns true on success, false if the new grid would exceed TSAPI_MAX_SPACES
 * or if columns is zero.
 * Note that the actual number of desktops present in the system is unchanged,
 * you should call tsapi_addDesktops or tsapi_removeDesktops after calling this
 * function.
 */
bool tsapi_setDefinedColumnsOnDisplay(unsigned int columns, CGDirectDisplayID displayID);

/*
 * Call this to free strings returned by the TotalSpaces API.
 */
void tsapi_freeString(char *str);

/*
 * Switch the display to the given space.
 * Returns false if the space number is invalid.
 */
bool tsapi_moveToSpaceOnDisplay(unsigned int spaceNumber, CGDirectDisplayID displayID);

/*
 * Set the name of a space.
 * The maximum length is 255 bytes. The name should be in UTF-8.
 * Returns true on success, false if the name was too long or the space number was invalid.
 */
bool tsapi_setNameForSpaceOnDisplay(unsigned int spaceNumber, char *name, CGDirectDisplayID displayID);

/*
 * Type for space change callback.
 */
typedef void (*space_change_callback_t)(unsigned int fromSpaceNumber, unsigned int toSpaceNumber, CGDirectDisplayID displayID);

/*
 * Set the function that will be called when the visible space changes.
 * There is only one callback per process, registering a new callback will supercede any previous one.
 */
void tsapi_setSpaceWillChangeCallback(space_change_callback_t callback);

/*
 * Cancel space change callbacks
 */
void tsapi_unsetSpaceWillChangeCallback();

/*
 * Type for layout change callback
 */
typedef void (*space_layout_changed_callback_t)(void);

/*
 * Set the function that will be called when the layout changes.
 * This could be any change - for instance adding or removing a fullscreen, changing the name of a space,
 * or a change of rows or columns.
 * It indicates that you should re-request any information you are holding on the spaces.
 * There is only one callback per process, registering a new callback will supercede any previous one.
 */
void tsapi_setLayoutChangedCallback(space_layout_changed_callback_t callback);

/*
 * Cancel layout change callbacks.
 */
void tsapi_unsetLayoutChangedCallback();

/*
 * Struct containing information about a window.
 */
struct tsapi_window {
  char *appName;
  unsigned int windowId;
  bool isOnAllSpaces;
  char *title;
  char *frame;
  CGDirectDisplayID displayID;
  unsigned int spaceNumber;
};

/*
 * Struct containing information about windows.
 * Contains a pointer to an array of tsapi_window structs.
 */
struct tsapi_windows {
  unsigned int windowCount;
  struct tsapi_window *windows;
};

/*
 * Return a pointer to a tsapi_windows struct containing information about all the windows
 * in all spaces.
 *
 * The windows are listed in space order for each display, and within each space
 * the windows are listed front to back, so earlier windows in the array are frontmost.
 *
 * You must call tsapi_freeWindowList when you have finished with this.
 */
struct tsapi_windows *tsapi_windowList();

/*
 * Free a previously returned tsapi_spaces struct
 */
void tsapi_freeWindowList(struct tsapi_windows *windowList);

/*
 * Move a window to a different space
 * The windowId must be one that has been returned in a tsapi_window struct
 *
 * Returns true on success, false if the windowID or spaceNumber was invalid
 */
bool tsapi_moveWindowToSpaceOnDisplay(unsigned int windowID, unsigned int spaceNumber, CGDirectDisplayID displayID);

/*
 * Move a space to another position
 * You cannot move space 1 when displays have separate spaces is turned off.
 *
 * Returns true on success, false if the spaceNumber or positionNumber was
 * invalid
 */
bool tsapi_moveSpaceToPositionOnDisplay(unsigned int spaceNumber, unsigned int positionNumber, CGDirectDisplayID displayID);

/*
 * Move a space to another position on another display
 * You cannot use this displays have separate spaces is turned off.
 * You cannot move a currently visible space.
 *
 * Returns true on success, false if any parameter was invalid.
 */
bool tsapi_moveSpaceOnDisplayToPositionOnDisplay(unsigned int spaceNumber, CGDirectDisplayID fromDisplayID, unsigned int positionNumber, CGDirectDisplayID toDisplayID);

/*
 * Add desktops
 * There can usually be at most 16 desktops, unless desktops have migrated
 * from another monitor.
 *
 * Returns the number of desktops actually added.
 */
unsigned int tsapi_addDesktopsOnDisplay(unsigned int numberToAdd, CGDirectDisplayID displayID);

/*
 * Remove desktops
 * Removes numberToRemove desktops. The highest numbered desktops are removed.
 *
 * Removing a desktop you are currently on will result in TotalSpaces switching to
 * another dektop.
 *
 * Any windows present on a desktop being removed will be moved to one of the
 * remaining desktops.
 *
 * Returns true on success, false if numberToRemove was zero or would result in less
 * than 1 desktop remaining.
 */
bool tsapi_removeDesktopsOnDisplay(unsigned int numberToRemove, CGDirectDisplayID displayID);

/*
 * Set the front window
 * Set the given window id to be at the front.
 */
void tsapi_setFrontWindow(unsigned int windowID);

#endif

