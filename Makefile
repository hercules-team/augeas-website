BUILD=build/html
BSTY=$(BUILD)/styles
ND_DOCSDIR=../augeas/doc/naturaldocs
BUILD_REFS=build/html/docs/references
LENS_DIR=../augeas/lenses
RELEASES=$(shell cd ../augeas && git tag | sed -n 's/release-\(.*\)/\1/p')
STOCK_LENSES_RELEASES=$(foreach release,$(RELEASES),pages/stock_lenses/$(release)/index.txt)
ND_RELEASES=$(foreach release,$(RELEASES),build/html/docs/references/$(release))

all: pages/stock_lenses.txt $(STOCK_LENSES_RELEASES) \
     rest2web $(BSTY)/default.css $(BSTY)/favicon.ico \
     $(BSTY)/augeas.css $(BSTY)/generic.css \
     $(BSTY)/default-debug.css $(BSTY)/debug.css \
     $(BSTY)/et_logo.png $(BSTY)/augeas-logo.png \
     $(BSTY)/footer_corner.png $(BSTY)/footer_pattern.png \
     $(BUILD)/docs/augeas.odp $(BUILD)/docs/augeas.pdf \
     $(BUILD)/docs/augeas-ols-2008.odp $(BUILD)/docs/augeas-ols-2008.pdf \
     naturaldocs

pages/stock_lenses.txt:
	ruby list_lenses.rb -f rst -l $(LENS_DIR) > $@

pages/stock_lenses/%/index.txt:
	mkdir -p pages/stock_lenses/$*
	cd ../augeas && \
	  git checkout . && \
	  git checkout release-$* && \
	  ruby $(CURDIR)/list_lenses.rb -f rst -l $(LENS_DIR) \
	    -r '../../' -v '$*' > \
	    $(CURDIR)/$@
	git add $@

naturaldocs:
	(if test -d $(ND_DOCSDIR); then \
	   $(MAKE) -C $(ND_DOCSDIR); \
          fi; \
	  rm -rf $(BUILD_REFS); \
          mkdir -p $(BUILD_REFS); \
	  cp -pr $(ND_DOCSDIR)/output/* $(BUILD_REFS))

rest2web:
	PYTHONPATH=$$PWD r2w

$(BUILD)/styles/%: pages/styles/%
	mkdir -p $(BUILD)/styles
	cp -a $< $@

$(BUILD)/docs/%.odp: pages/docs/%.odp
	@mkdir -p $(shell dirname $@)
	cp -up $< $@

$(BUILD)/docs/%.pdf: pages/docs/%.pdf
	@mkdir -p $(shell dirname $@)
	cp -up $< $@

sync:
	git checkout gh-pages
	rsync -av build/html/ .
	git status
	# Add new doc
	find . -not -path './build/html/*' -type f \
	  -name '*.html' -exec git add {} \;
	git commit -a && git checkout master

clean:
	rm -f pages/stock_lenses.txt
	rm -rf $(BUILD)

.PHONY: rest2web sync clean naturaldocs
