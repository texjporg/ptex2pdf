
PROJECT=ptex2pdf
DESTTREE ?= `kpsewhich -var-value TEXMFLOCAL`
SCRIPTVERSION = $(shell texlua ptex2pdf.lua --print-version)

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
	@if [ -r $(PROJECT)-$(SCRIPTVERSION).tar.gz ] ; then \
	  echo "$(PROJECT)-$(SCRIPTVERSION).tar.gz already there, not overwriting it!" >&2 ; \
	else \
	  git archive --format=tar --prefix=$(PROJECT)-$(SCRIPTVERSION)/ HEAD | gzip -c > $(PROJECT)-$(SCRIPTVERSION).tar.gz ; \
	  echo "$(PROJECT)-$(SCRIPTVERSION).tar.gz is ready" ; \
	fi


clean:
	-rm -f README

