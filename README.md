# vlibsql

## vlang bindings for libsql-c

learn more at
[libsql-c](https://github.com/tursodatabase/libsql-c)

## note

- V ORM is not yet supported
- [libsql-c](https://github.com/tursodatabase/libsql-c) SDK is currently in technical preview, and mostly used for internal use when building other libSQL SDKs
- libsql-c does not expose the sqlite compatible C api

# building
cargo and rust need to be installed [Rust and Cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html)

1. this will install libsql-c if not found


```bash
make update
```

2. dynamic library (example)

```bash
make update LIBRARY_LIB=liblibsql.dylib
```

## manually

1. Clone the repository:

   ```bash
   git clone https://github.com/tursodatabase/libsql-c.git
   cd libsql-c
   ```

2. Build the library:

- default: `cargo build --release`
- with encryption: `cargo build --release --features encryption`

3. The compiled library will be in `libsql-c/target/release/`:

   - `liblibsql.so` (Linux)
   - `liblibsql.dylib` (macOS)
   - `liblibsql.dll` (Windows)
   - `liblibsql.a` (static)

4. Copy `libsql.h` and the compiled library to ./thirdparty

5. this wrapper supports static library or dynamic library

