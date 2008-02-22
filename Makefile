all:
	cp -pr pages/styles build/html
	python /homes/lutter/packages/rest2web-0.5.1/r2w.py
