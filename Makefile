BUILD=build/html
all: rest2web $(BUILD)/styles/default.css $(BUILD)/styles/favicon.ico

rest2web:
	python /homes/lutter/packages/rest2web-0.5.1/r2w.py

$(BUILD)/styles/%: pages/styles/%
	mkdir -p $(BUILD)/styles
	cp -a $< $@

sync:
	rsync -rav $(RSYNC_OPTS) $(BUILD)/ et:/var/www/sites/augeas.et.redhat.com/
clean:
	rm -rf $(BUILD)

.PHONY: rest2web sync clean
