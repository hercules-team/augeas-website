BUILD=build/html
BSTY=$(BUILD)/styles
ND_DOCSDIR=../augeas/doc/naturaldocs
BUILD_REFS=build/html/docs/references
BUILD_REFS_CACHE=build_cache/html/docs/references
LENS_DIR=../augeas/lenses
RELEASES=$(shell cd ../augeas && git tag | sed -n 's/release-\(.*\)/\1/p')
STOCK_LENSES_RELEASES=$(foreach release,$(RELEASES),pages/stock_lenses/$(release)/index.txt)
ND_RELEASES=$(foreach release,$(RELEASES),$(BUILD_REFS)/$(release))

all: pages/stock_lenses.txt $(STOCK_LENSES_RELEASES) \
     rest2web $(BSTY)/default.css $(BSTY)/favicon.ico \
     $(BSTY)/augeas.css $(BSTY)/generic.css \
     $(BSTY)/default-debug.css $(BSTY)/debug.css \
     $(BSTY)/et_logo.png $(BSTY)/augeas-logo.png \
     $(BSTY)/footer_corner.png $(BSTY)/footer_pattern.png \
     $(BUILD)/docs/augeas.odp $(BUILD)/docs/augeas.pdf \
     $(BUILD)/docs/augeas-ols-2008.odp $(BUILD)/docs/augeas-ols-2008.pdf \
     naturaldocs $(ND_RELEASES)

pages/stock_lenses.txt:
	ruby list_lenses.rb -f rst -l $(LENS_DIR) > $@

pages/stock_lenses/%/index.txt:
	mkdir -p pages/stock_lenses/$*
	cd ../augeas && \
	  git checkout -f release-$* && \
	  ruby $(CURDIR)/list_lenses.rb -f rst -l $(LENS_DIR) \
	    -r '../../' -v '$*' > \
	    $(CURDIR)/$@
	git add $@

naturaldocs:
	cd ../augeas && git checkout -f master
	(if test -d $(ND_DOCSDIR); then \
	   $(MAKE) -C $(ND_DOCSDIR); \
          fi; \
	  rm -rf $(BUILD_REFS); \
          mkdir -p $(BUILD_REFS); \
	  rsync -a $(BUILD_REFS_CACHE)/ $(BUILD_REFS); \
	  cp -pr $(ND_DOCSDIR)/output/* $(BUILD_REFS))

$(BUILD_REFS)/%:
	cd ../augeas && git checkout -f release-$*
	if ! test -d $@; then \
	  (if test -d $(ND_DOCSDIR); then \
	    $(MAKE) -C $(ND_DOCSDIR); \
            fi; \
	    mkdir -p $@; \
	    cp -pr $(ND_DOCSDIR)/output/* $@; \
	    mkdir -p $(BUILD_REFS_CACHE)/$*; \
	    rsync -a $@/ $(BUILD_REFS_CACHE)/$*; \
	    git add $(BUILD_REFS_CACHE)/$*); \
	fi


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
	  -name '*.html' -or -name '*.js' -or -name '*.css' \
	  -exec git add {} \;
	git commit -a && git checkout master

clean:
	rm -f pages/stock_lenses.txt
	rm -rf $(BUILD)

.PHONY: rest2web sync clean naturaldocs
