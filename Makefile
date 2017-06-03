
PROJECT=ptex2pdf
DESTTREE ?= `kpsewhich -var-value TEXMFLOCAL`
SCRIPTVERSION = $(shell texlua ptex2pdf.lua --print-version)

.PHONY: default install release
default: README.md


README: README.md
	pandoc --from=markdown_github --to=plain --columns=80 README.md > README

README.md: ptex2pdf.lua
	texlua ptex2pdf.lua --readme > README.md

install: README.md
	mkdir -p $(DESTTREE)/scripts/ptex2pdf
	cp ptex2pdf.lua $(DESTTREE)/scripts/ptex2pdf
	mkdir -p $(DESTTREE)/doc/latex/ptex2pdf
	cp COPYING $(DESTTREE)/doc/latex/ptex2pdf/
	cp README.md $(DESTTREE)/doc/latex/ptex2pdf/README

release: README.md
	sh release.sh


clean:
	-rm -f README

