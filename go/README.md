# Go Library for TotalSpaces2 API

You want it?

```
go install github.com/binaryage/totalspaces2-api/go/totalspaces2
```

## Forks


If you fork this repo and want it to work, it will still require you
to go get the original

```
go get github.com/binaryage/totalspaces2-api/go/totalspaces2
```

Because the `libtotalspaces2api.dylib` has to be stored in a specific
path relative to your `$GOPATH/bin`, in this case
`../src/github.com/binaryage/totalspaces2-api/go/totalspaces2`

You can change it locally if you want like this...

```
install_name_tool -id "@executable_path/../src/github.com/$GH_USER_NAME/$GH_FORK_NAME/go/totalspaces2/libtotalspaces2api.dylib" totalspaces2/libtotalspaces2api.dylib
```

but if you're hoping to merge upstream to
`binaryage/totalspaces2-api`, then you'll need to not change this in
your upstream PR.

In all other ways, `libtotalspaces2api.dylib` is an exact copy of
`../ruby/lib/libtotalspaces2api.dylib`. If that file changes, we'll
need to change the copy in `go/totalspaces2` to use the new version,
and the install name tool command must be run, otherwise it'll use the
default which is `@executable_path/../Frameworks`, where it defintely
won't be.
