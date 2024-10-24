# module vlibsql


## Contents
- [blob](#blob)
- [connect](#connect)
- [get_value_type](#get_value_type)
- [integer](#integer)
- [null](#null)
- [real](#real)
- [setup](#setup)
- [text](#text)
- [Libsql_config_t](#Libsql_config_t)
- [Libsql_result_value_t](#Libsql_result_value_t)
- [Libsql_slice_t](#Libsql_slice_t)
- [Libsql_value_t](#Libsql_value_t)
- [Row](#Row)
  - [free](#free)
  - [value](#value)
  - [name](#name)
  - [length](#length)
  - [empty](#empty)
- [Rows](#Rows)
  - [free](#free)
  - [next](#next)
  - [column_name](#column_name)
  - [column_length](#column_length)
- [Statement](#Statement)
  - [free](#free)
  - [execute](#execute)
  - [query](#query)
  - [reset](#reset)
  - [bind_named](#bind_named)
  - [bind_value](#bind_value)
- [Transaction](#Transaction)
  - [free](#free)
  - [commit](#commit)
  - [rollback](#rollback)
  - [prepare](#prepare)
  - [batch](#batch)
- [Libsql_cypher_t](#Libsql_cypher_t)
- [C.libsql_slice_t](#C.libsql_slice_t)
- [C.libsql_value_t](#C.libsql_value_t)
- [C.libsql_value_union_t](#C.libsql_value_union_t)
- [Config](#Config)
- [DB](#DB)
  - [free](#free)
  - [info](#info)
  - [prepare](#prepare)
  - [batch](#batch)
  - [transaction](#transaction)
  - [sync](#sync)

## blob
[[Return to contents]](#Contents)

## connect
[[Return to contents]](#Contents)

## get_value_type
[[Return to contents]](#Contents)

## integer
```v
fn integer(i i64) Libsql_value_t
```
VALUES

[[Return to contents]](#Contents)

## null
[[Return to contents]](#Contents)

## real
[[Return to contents]](#Contents)

## setup
```v
fn setup(config Libsql_config_t) !
```
UTILS

[[Return to contents]](#Contents)

## text
[[Return to contents]](#Contents)

## Libsql_config_t
[[Return to contents]](#Contents)

## Libsql_result_value_t
[[Return to contents]](#Contents)

## Libsql_slice_t
[[Return to contents]](#Contents)

## Libsql_value_t
[[Return to contents]](#Contents)

## Row
## free
```v
fn (mut row Row) free()
```
Row

[[Return to contents]](#Contents)

## value
```v
fn (row Row) value(index int) !Libsql_value_t
```
Get the value at the the index

[[Return to contents]](#Contents)

## name
```v
fn (row Row) name(index int) string
```
Get the column name at the the index

[[Return to contents]](#Contents)

## length
```v
fn (row Row) length() int
```
Get row column count

[[Return to contents]](#Contents)

## empty
```v
fn (row Row) empty() bool
```
Check if the row is empty, indicating the end of `Rows.next()`

[[Return to contents]](#Contents)

## Rows
## free
```v
fn (mut rows Rows) free()
```
ROWS

[[Return to contents]](#Contents)

## next
```v
fn (mut rows Rows) next() ?Row
```
Get the next row from rows

[[Return to contents]](#Contents)

## column_name
```v
fn (mut rows Rows) column_name(index int) string
```
Get the column name at the index

[[Return to contents]](#Contents)

## column_length
```v
fn (mut rows Rows) column_length() int
```
Get rows column count

[[Return to contents]](#Contents)

## Statement
## free
```v
fn (mut stmt Statement) free()
```
Statement

[[Return to contents]](#Contents)

## execute
```v
fn (stmt Statement) execute() !u64
```
Execute a statement

[[Return to contents]](#Contents)

## query
```v
fn (stmt Statement) query() !Rows
```
Query a statement

[[Return to contents]](#Contents)

## reset
```v
fn (stmt Statement) reset()
```
Reset a statement

[[Return to contents]](#Contents)

## bind_named
```v
fn (stmt Statement) bind_named(name string, val Libsql_value_t) !
```
Bind a named argument to a statement

[[Return to contents]](#Contents)

## bind_value
```v
fn (stmt Statement) bind_value(val Libsql_value_t) !
```
Bind a positional argument to a statement

[[Return to contents]](#Contents)

## Transaction
## free
```v
fn (mut tx Transaction) free()
```
Transaction

[[Return to contents]](#Contents)

## commit
```v
fn (tx Transaction) commit()
```
Deallocate and commit a transaction (transaction becomes invalid)

[[Return to contents]](#Contents)

## rollback
```v
fn (tx Transaction) rollback()
```
Deallocate and rollback a transaction (transaction becomes invalid)

[[Return to contents]](#Contents)

## prepare
```v
fn (tx Transaction) prepare(_sql string) !Statement
```
Prepare a statement in a transaction

[[Return to contents]](#Contents)

## batch
```v
fn (tx Transaction) batch(_sql string) !
```
Send a batch statement in a transaction

[[Return to contents]](#Contents)

## Libsql_cypher_t
[[Return to contents]](#Contents)

## C.libsql_slice_t
[[Return to contents]](#Contents)

## C.libsql_value_t
[[Return to contents]](#Contents)

## C.libsql_value_union_t
[[Return to contents]](#Contents)

## Config
```v
struct Config {
pub mut:
	url                      string
	path                     string
	auth_token               string
	encryption_key           string
	sync_interval            u64
	webpki                   bool
	cypher                   Libsql_cypher_t
	disable_read_your_writes bool
}
```
@[unsafe] pub fn (mut err LibsqlError) free() { C.libsql_error_deinit(err.libsql_error) unsafe { free(err) } }

[[Return to contents]](#Contents)

## DB
[[Return to contents]](#Contents)

## free
[[Return to contents]](#Contents)

## info
[[Return to contents]](#Contents)

## prepare
```v
fn (db DB) prepare(_sql string) !Statement
```
Prepare a statement in a connection

[[Return to contents]](#Contents)

## batch
```v
fn (db DB) batch(_sql string) !
```
Send a batch statement in a connection

[[Return to contents]](#Contents)

## transaction
```v
fn (db DB) transaction() !Transaction
```
Begin a transaction

[[Return to contents]](#Contents)

## sync
```v
fn (db DB) sync() !Sync
```
Sync frames with the primary

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 24 Oct 2024 15:34:48
