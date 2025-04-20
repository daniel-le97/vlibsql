
.PHONY: docs fmt test run symlink clean-symlink clean-examples update examples

LIBRARY_LIB ?= liblibsql.a

LINUX_CMD = cargo build --release
MACOS_CMD = cargo build --release --features encryption

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

install-rust:
	@if [ ! $(shell which cargo) ]; then \
        echo "Rust is not installed. Do you want to install it? (yes/no)"; \
        read answer; \
        if [ "$$answer" = "yes" ]; then \
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh; \
        else \
            echo "Rust installation skipped."; \
			exit 1; \
        fi; \
    else \
        echo "Rust is already installed."; \
    fi

update: install-rust
	@if [ ! -d "$(CURDIR)/libsql-c" ]; then \
		echo "libsql-c does not exist, installing..."; \
		git clone https://github.com/tursodatabase/libsql-c.git $(CURDIR)/libsql-c; \
	fi
	@if [ "$(shell uname)" = "Darwin" ]; then \
		cd $(CURDIR)/libsql-c && git pull && $(MACOS_CMD); \
	else \
		cd $(CURDIR)/libsql-c && git pull && $(LINUX_CMD); \
    fi
	mv $(CURDIR)/libsql-c/target/release/$(LIBRARY_LIB) $(CURDIR)/thirdparty/$(LIBRARY_LIB)
	cp $(CURDIR)/libsql-c/libsql.h $(CURDIR)/thirdparty/libsql.h

examples:
	@if [ "$(shell uname)" = "Darwin" ]; then \
		v examples/encrypted.v; \
    fi
	v examples/local.v
	v examples/memory.v
	v examples/remote.v
	v examples/sync.v
	v examples/orm.v