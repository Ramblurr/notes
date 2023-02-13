.PHONY: build
build:
	mdkocs build

.PHONY: serve
serve:
	mkdocs serve

.PHONY: clean
clean:
	rm -rf ./site
