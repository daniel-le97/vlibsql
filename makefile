
.PHONY: docs fmt test run symlink clean-symlink clean-examples

docs:
	rm -rf ./docs
	v doc ./src -comments -f markdown -o - > docs.md
	v doc ./src -f html -o ./docs/
	mv ./docs/vlibsql.html ./docs/index.html
	python3 -m http.server --directory ./docs


fmt:
	v fmt -w .

test:
	v -stats test ./tests

run:
	v run .

symlink:
	ln -s $(CURDIR) $(HOME)/.vmodules/vlibsql

clean-symlink:
	rm -rf $(HOME)/.vmodules/vlibsql


clean-examples:
	find ./examples -type f ! -name "*.v" -exec rm {} \;

