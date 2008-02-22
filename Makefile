BUILD=build/html
all:
	mkdir -p $(BUILD)
	cp -pr pages/styles $(BUILD)
	python /homes/lutter/packages/rest2web-0.5.1/r2w.py
clean:
	rm -rf $(BUILD)
