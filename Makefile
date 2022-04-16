.PHONY: deps compile test

default: deps compile test

deps:
	scripts/dep.sh Olical aniseed origin/master

compile:
	deps/aniseed/scripts/compile.sh

full-compile:
	rm -rf lua
	deps/aniseed/scripts/compile.sh
	deps/aniseed/scripts/embed.sh aniseed matchparen

test:
	rm -rf test/lua
	deps/aniseed/scripts/test.sh
