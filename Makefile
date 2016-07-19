IMPORT_PATH      := github.com/FiloSottile/helloworld

.PHONY: all
all: hello

.PHONY: hello bin/hello
hello: bin/hello
bin/hello: .GOPATH/.ok
	go install $(VERSION_FLAGS) -v $(IMPORT_PATH)/cmd/hello

##### =====> Utility targets <===== #####

.PHONY: clean test list cover format

clean:
	rm -rf bin .GOPATH

test: .GOPATH/.ok
	go test -v -i -race $(allpackages) # install -race libraries
ifndef CI
	go test -race $(allpackages)
else
	@mkdir -p .GOPATH/test
	go test -v -race $(allpackages) | tee .GOPATH/test/output.txt
endif

list: .GOPATH/.ok
	@echo $(allpackages)

cover: bin/gocovmerge .GOPATH/.ok
	rm -f .GOPATH/cover/*.out .GOPATH/cover/all.merged
	@mkdir -p .GOPATH/cover
	@echo "-- go test -coverpkg=./... -coverprofile=.GOPATH/cover/... ./..."
	@for MOD in $(allpackages); do \
		go test -coverpkg=`echo $(allpackages)|tr " " ","` \
			-coverprofile=.GOPATH/cover/unit-`echo $$MOD|tr "/" "_"`.out \
			$$MOD 2>&1 | grep -v "no packages being tested depend on" || exit 1; \
	done
	./bin/gocovmerge .GOPATH/cover/*.out > .GOPATH/cover/all.merged
ifndef CI
	go tool cover -html .GOPATH/cover/all.merged
else
	go tool cover -html .GOPATH/cover/all.merged -o .GOPATH/cover/all.html
endif
	@echo ""
	@echo "=====> Total test coverage: <====="
	@go tool cover -func .GOPATH/cover/all.merged

format: bin/goimports .GOPATH/.ok
	ls .GOPATH/src/$(IMPORT_PATH)/**/*.go | grep -v /vendor/ | xargs ./bin/goimports -w

##### =====> Internals <===== #####

VERSION          := $(shell git describe --tags --always --dirty="-dev")
DATE             := $(shell date '+%Y-%m-%d-%H%M UTC')
VERSION_FLAGS    := -ldflags='-X "main.Version=$(VERSION)" -X "main.BuildTime=$(DATE)"'

# cd into the GOPATH to workaround ./... not following symlinks
allpackages = $(shell ( cd $(CURDIR)/.GOPATH/src/$(IMPORT_PATH) && \
    GOPATH=$(CURDIR)/.GOPATH go list ./... 2>&1 1>&3 | \
    grep -v /vendor/ 1>&2 ) 3>&1 | grep -v /vendor/)

export GOPATH := $(CURDIR)/.GOPATH

.GOPATH/.ok:
	mkdir -p "$(dir .GOPATH/src/$(IMPORT_PATH))"
	ln -s ../../../.. ".GOPATH/src/$(IMPORT_PATH)"
	mkdir -p bin
	ln -s ../bin .GOPATH/bin
	touch $@

.PHONY: bin/gocovmerge bin/goimports
bin/gocovmerge: .GOPATH/.ok
	go install $(IMPORT_PATH)/vendor/github.com/wadey/gocovmerge
bin/goimports: .GOPATH/.ok
	go install $(IMPORT_PATH)/vendor/golang.org/x/tools/cmd/goimports
