# vlibsql

## vlang bindings for libsql-c

learn more at
[libsql-c](https://github.com/tursodatabase/libsql-c)

## note

- V ORM is not yet supported
- [libsql-c](https://github.com/tursodatabase/libsql-c) SDK is currently in technical preview, and mostly used for internal use when building other libSQL SDKs

## building libsql-c manually

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

4. Copy `libsql.h` and the compiled library to your project directory or a standard system location.

5. this wrapper uses liblibsql.a
