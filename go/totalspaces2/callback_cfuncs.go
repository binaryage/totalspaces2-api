// +build darwin,cgo

package totalspaces2

/*

#include <stdio.h>
#cgo CFLAGS: -x objective-c -I../../ruby/lib
#cgo LDFLAGS: -L../../ruby/lib -ltotalspaces2api
#include <TSLib.h>

extern void goSpaceChangeCallback(unsigned int from, unsigned int to, CGDirectDisplayID display);
extern void goSpaceLayoutChangedCallback();

// The gateway functions
void goSpaceChangeCallback_cgo(unsigned int to, unsigned int from, CGDirectDisplayID display)
{
    void goSpaceChangeCallback(unsigned int, unsigned int, CGDirectDisplayID);
    return goSpaceChangeCallback(to, from, display);
}

void goSpaceLayoutChangedCallback_cgo ()
{
    void goSpaceLayoutChangedCallback();
    return goSpaceLayoutChangedCallback();
}
*/
import "C"
