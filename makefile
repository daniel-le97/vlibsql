
.PHONY: docs fmt test run symlink clean-symlink clean-examples update examples

LIBRARY_LIB ?= liblibsql.a

docs:
	rm -rf ./docs
	v doc ./src -comments -f markdown -o - > docs.md
	v doc ./src -f html -o ./docs/
	mv ./docs/vlibsql.html ./docs/index.html
	python3 -m http.server --directory ./docs


fmt:
	v fmt -w .

test:
	v -stats test .

run:
	v run .

symlink:
	ln -s $(CURDIR) $(HOME)/.vmodules/vlibsql

clean-symlink:
	rm -rf $(HOME)/.vmodules/vlibsql


clean-examples:
	find ./examples -type f ! -name "*.v" -exec rm {} \;

update:
	@if [ -d "$(CURDIR)/libsql-c" ]; then \
		echo "libsql-c exists, proceeding with update..."; \
		cd $(CURDIR)/libsql-c && git pull && cargo build --release --features encryption; \
		mv $(CURDIR)/libsql-c/target/release/$(LIBRARY_LIB) $(CURDIR)/thirdparty/$(LIBRARY_LIB); \
		cp $(CURDIR)/libsql-c/libsql.h $(CURDIR)/thirdparty/libsql.h; \
	else \
		echo "libsql-c does not exist, installing..."; \
		git clone https://github.com/tursodatabase/libsql-c.git $(CURDIR)/libsql-c; \
		cd $(CURDIR)/libsql-c && cargo build --release --features encryption; \
		mv $(CURDIR)/libsql-c/target/release/$(LIBRARY_LIB) $(CURDIR)/thirdparty/$(LIBRARY_LIB); \
		cp $(CURDIR)/libsql-c/libsql.h $(CURDIR)/thirdparty/libsql.h; \
	fi

examples:
	v examples/encrypted.v
	v examples/local.v
	v examples/memory.v
	v examples/remote.v
	v examples/sync.v
	v examples/orm.v
