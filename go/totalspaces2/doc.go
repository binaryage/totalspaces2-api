/*
Package totalspaces2 provides Go API bindings for TotalSpaces2 from
BinaryAge

It should work out of the box with your local Golang install, using
CGo to bridge between Go and the libtotalspaces2api.dylib

You can use this package in various ways. For instance you could:

* Display a message or alert when a particular space is moved to

* Automatically change the name of spaces depending on what apps are in them

* Record which spaces certain windows are on, and restoring those windows to those spaces when the owning app restarts

* Trigger moving windows between spaces

API support, and support for this package starts with TotalSpaces2
v2.1.0. The API is a premium feature, and will only work with
registered versions of TotalSpaces2.

Examples:


*/
package totalspaces2
