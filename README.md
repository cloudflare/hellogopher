# Hellogopher: "just clone and `make`"

Hellogopher is a Makefile that makes your conventional Go project build from anywhere, for anyone, with just `make`.

## Quickstart

```
wget https://raw.githubusercontent.com/cloudflare/hellogopher/master/Makefile
$EDITOR Makefile # modify IMPORT_PATH
make setup
git add Makefile .gitignore vendor/
```

You can now just clone the repository anywhere, and `make` it. `go get` still works as usual.

```
$ make
$ ./bin/hello
Hello, world!

$ make test
$ make cover
```

If you get `cannot find package` errors, you need to read the *Vendoring* section.

![demo](https://cloud.githubusercontent.com/assets/1225294/22173691/f2d297ce-dfca-11e6-910f-11b416e4e75a.gif)

### What is `IMPORT_PATH`?

`IMPORT_PATH` is the absolute unique name of your repository. It's usually where it can be found, too. For example `github.com/FiloSottile/example`.

You use the `IMPORT_PATH` any time you want to refer to your code: in the Makefile, with `import`, with `go get`.

If your `IMPORT_PATH` is `github.com/FiloSottile/example`, the code in the root of your repository is `github.com/FiloSottile/example` (and it will compile to a binary named `example`), the code in the folder `foo` is `github.com/FiloSottile/example/foo`, `cmd/bar` is `github.com/FiloSottile/example/cmd/bar`, and so on.

If you change the `IMPORT_PATH` you have to run `make clean`.

## Vendoring

A hellogopher project uses the official Go vendoring style: third-party packages go in `./vendor/`, like `./vendor/github.com/fatih/color`. The Makefile will intentionally ignore your system GOPATH to force you to vendor.

Hellogopher has no opinions on how you populate the vendor folder, but a tool that is guaranteed to work as flexibly as hellogopher is [gvt](https://github.com/FiloSottile/gvt). If you use `make setup` you'll find gvt in `./bin/gvt`.

Don't forget to check the vendor folder into your VCS.

```
./bin/gvt fetch github.com/fatih/color
git add vendor/
```

## Using editors and other tools

All the tools used by the Makefile have been vetted and fixed to work out of the box. However, most other tools (`gometalinter`, `guru`, ...) and editors are very likely not to work unless you place the repository at `$GOPATH/src/$IMPORT_PATH`.

The point of hellogopher is not to be an universal wrapper or the only tool you use, but to get you started easily before you learn GOPATH.

## Why

Go developers should know and use GOPATH. But **it shouldn't be the first thing they are exposed to**. At Cloudflare we noticed it was the main cause of friction for novice or casual Go users. They expect to **just clone a repository anywhere, and be able to build it**.

Hellogopher allows non-Go developers to easily build the project in any environment, and provides enough tools (`test`, `cover`, `format`) for the casual contributor.

Still, a hellogopher project is just a **standard `go get`-able project**. Regular Go developers should place the repository at its proper place in the GOPATH, so they can use all other tools that expect a GOPATH. (And they can still benefit from the convenience methods like `make cover` and the vendoring enforcement.)

Hellogopher makes your install instructions look like this:

```
go get -u github.com/FiloSottile/zcash-mini
 - or -
git clone https://github.com/FiloSottile/zcash-mini
cd zcash-mini && make && sudo cp ./bin/zcash-mini /usr/local/bin/
```

It achieves similar results to [gb](https://getgb.io/), but preserving the conventional structure of a Go project. It works similarly to the Camlistore build system but without the temporary copies.

## Features

A hellogopher-based project is a proper Go repository, so you can `go get` it and import it from other packages.  But *at the same time* it includes a powerful Makefile that isolates the build from the system and works from anywhere, without having to setup a GOPATH.

### make

A standard build target builds a binary and places it in `bin/`.

Version and build time are injected at link time.

All operations take full advantage of **incremental builds**.

The system GOPATH is ignored, so only vendored dependencies are used.

### make test

`make test` runs `go vet` and `go test -race` on all packages, excluding those matching a pattern in `IGNORED_PACKAGES`.

`GODEBUG=cgocheck=2` is set so that the (expensive) full suite of cgo checks are run during tests. It has no effect if you don't use cgo.

It installs the race libraries (in the hidden GOPATH) just so it does not have to compile them the next time.

### make cover

`make cover` aggregates the coverage of all tests over all packages. That is, it runs the test suite of all packages, each time collecting the coverage over all packages, and then aggregates all those reports into one.

It prints detailed statistics and opens the full HTML report in the browser.

*Note: `make cover` does not exit 1 on failure.*

### make format

`make format` runs `goimports` on all non-ignored packages.

### CI mode

CI mode is enabled if the environment variable `CI` is set to 1.

The `make test` full verbose output is both sent to stdout/stderr, and saved in `.GOPATH/test/vet.txt` and `.GOPATH/test/output.txt`.

The `make cover` HTML report is saved in `.GOPATH/cover/all.html`.

### Cross-compiling

You can cross-compile easily with `GOOS=linux make`. The generated binary will end up in `bin/OS_ARCH/`, like `bin/linux_amd64/hello`.

Hellogopher works nicely also if you share a folder between architectures, for example with Docker for Mac.

## Tips and FAQ

Don't use **relative imports** (the ones starting with `./`). Just don't. No, really.

Binary targets are **.PHONY** because hellogopher uses the Go native incremental build support.

Binaries will be **named after the folder they are in**. If your `package main` is in the repository root and not in a subfolder, the binary will be named after the repository name. This is a fundamental concept of Go.

To **exclude a package** from `make test`/`cover`/`list`/`format` add its name (or a part of it) to `IGNORED_PACKAGES`. By default vendored packages are excluded. You might need to do this if you have 3rd party code outside of `vendor/`, too.

If you add Makefile binary targets don't forget the **`.GOPATH/.ok`** dependency.

If you need to `go build` a lone **`.go` file** instead of a package, first stop and think if it shouldn't be a package instead.  Then if you insist build them like this:

```
go build $(GOPATH)/src/$(IMPORT_PATH)/my/go/file.go
```

To run the Makefile verbosely, **printing commands and build progress**, set `V := 1` at the top of the Makefile. You can use `make $TARGET V=1` and `make $TARGET V=` to control this on a per-call basis.

## How does this work?

*You don't need to read, understand or like this to use hellogopher.*

The trick to the magic Makefile is that it creates a GOPATH in .GOPATH, and places a
symlink back to the root of the repo at the position where your package is supposed to be.

For example, `.GOPATH/src/github.com/FiloSottile/example -> ../../../..`.

It then uses .GOPATH as the GOPATH, and runs `go install`.

The GOPATH is permanent and local, and changes don't need to be synced since it uses a symlink to the repo. So incremental builds just work.

There are a lot of workarounds to make the symlink work, but they all revolve around the fact that `./...` does not traverse the symlink. So instead we first cd into it, and run `go list ./...` from that perspective. Similarly, goimports needs to know that the files are relative to the GOPATH to recognize the vendor folder, so we pass prefixed paths to it.

This is a bit complex, but the idea is that if you use other tools, you'll place the package in the right place in your system GOPATH and not use the symlink trick.  All the work to make the Makefile tools work with symlinks has already been done for you :)
