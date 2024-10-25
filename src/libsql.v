module vlibsql

#flag -I @VMODROOT/thirdparty/
#flag -L @VMODROOT/thirdparty/
#flag -llibsql
#flag darwin -framework CoreFoundation
#flag darwin -framework Security
#include "libsql.h"

@[flags]
pub enum Libsql_cypher_t {
	default = 0
	aes_256
}

enum Libsql_type_t {
	integer = 1
	real    = 2
	text    = 3
	blob    = 4
	null    = 5
}

pub fn get_value_type(val int) Libsql_type_t {
	match val {
		1 { return Libsql_type_t.integer }
		2 { return Libsql_type_t.real }
		3 { return Libsql_type_t.text }
		4 { return Libsql_type_t.blob }
		else { return Libsql_type_t.null }
	}
}

enum Libsql_tracing_level_t {
	libsql_tracing_level_error = 1
	libsql_tracing_level_warn
	libsql_tracing_level_info
	libsql_tracing_level_debug
	libsql_tracing_level_trace
}

@[typedef]
struct C.libsql_error_t {}

// @[typedef]
// struct C.libsql_slice_t {}

// @[typedef]
// struct C.libsql_value_t {}

type Libsql_database_t = C.libsql_database_t

pub type Libsql_slice_t = C.libsql_slice_t
pub type Libsql_value_t = C.libsql_value_t
type Libsql_error_t = C.libsql_error_t
type Libsql_log_t = C.libsql_log_t
type Libsql_database_desc_t = C.libsql_database_desc_t
pub type Libsql_config_t = C.libsql_config_t
type Libsql_batch_t = C.libsql_batch_t
type Libsql_rows_t = C.libsql_rows_t
type Libsql_row_t = C.libsql_row_t
pub type Libsql_result_value_t = C.libsql_result_value_t
type Libsql_sync_t = C.libsql_sync_t
type Libsql_bind_t = C.libsql_bind_t
type Libsql_execute_t = C.libsql_execute_t
type Libsql_connection_t = C.libsql_connection_t
type Libsql_statement_t = C.libsql_statement_t
type Libsql_transaction_t = C.libsql_transaction_t
type Libsql_connection_info_t = C.libsql_connection_info_t

@[typedef]
struct C.libsql_log_t {
	message   &char
	target    &char
	file      &char
	timestamp u64
	line      usize
	level     Libsql_tracing_level_t
}

@[typedef]
struct C.libsql_database_t {
	err   &Libsql_error_t
	inner voidptr
}

@[typedef]
struct C.libsql_connection_t {
	err   &Libsql_error_t
	inner voidptr
}

@[typedef]
struct C.libsql_statement_t {
	err   &Libsql_error_t
	inner voidptr
}

@[typedef]
struct C.libsql_transaction_t {
	err   &Libsql_error_t
	inner voidptr
}

@[typedef]
struct C.libsql_rows_t {
	err   &Libsql_error_t
	inner voidptr
}

@[typedef]
struct C.libsql_row_t {
	err   &Libsql_error_t
	inner voidptr
}

@[typedef]
struct C.libsql_batch_t {
	err &Libsql_error_t
}

@[typedef]
pub struct C.libsql_slice_t {
pub:
	ptr voidptr
	len usize
}

@[typedef]
pub union C.libsql_value_union_t {
pub:
	integer i64
	real    f64
	text    C.libsql_slice_t
	blob    C.libsql_slice_t
}

@[typedef]
pub struct C.libsql_value_t {
pub:
	value C.libsql_value_union_t
	type  int
}

@[typedef]
struct C.libsql_result_value_t {
	err &Libsql_error_t
	ok  Libsql_value_t
}

@[typedef]
struct C.libsql_sync_t {
	err           &Libsql_error_t
	frame_no      u64
	frames_synced u64
}

@[typedef]
struct C.libsql_bind_t {
	err &Libsql_error_t
}

@[typedef]
struct C.libsql_execute_t {
	err          &Libsql_error_t
	rows_changed u64
}

@[typedef]
struct C.libsql_connection_info_t {
	err                 &Libsql_error_t
	last_inserted_rowid i64
	total_changes       u64
}

//* *Database description.
//

@[params; typedef]
struct C.libsql_database_desc_t {
mut:
	//*The url to the primary database
	url &char
	//*Path to the database file or `:memory:`
	path &char
	//*Auth token to access the primary
	auth_token &char
	//*Encryption key to encrypt and decrypt the database in `path`
	encryption_key &char
	//*Interval to periodicaly sync with primary
	sync_interval u64
	//*Cypher to be used with `encryption_key`
	cypher int
	//*If set, disable `read_your_writes`. To mantain consistency.
	disable_read_your_writes bool
	//*Enable Webpki connector
	webpki bool
}

@[typedef]
struct C.libsql_config_t {
	logger  fn (C.libsql_log_t)
	version &char
}

//*Setup some global info
fn C.libsql_setup(config Libsql_config_t) &Libsql_error_t

//*Get the error message from a error
fn C.libsql_error_message(self &Libsql_error_t) &char

//*Create or open a database
fn C.libsql_database_init(desc Libsql_database_desc_t) Libsql_database_t

//*Sync frames with the primary
fn C.libsql_database_sync(self Libsql_database_t) Libsql_sync_t

//*Connect with the database
fn C.libsql_database_connect(self Libsql_database_t) Libsql_connection_t

//*Begin a transaction
fn C.libsql_connection_transaction(self Libsql_connection_t) Libsql_transaction_t

//*Send a batch statement in a connection
fn C.libsql_connection_batch(self Libsql_connection_t, const_sql &char) Libsql_batch_t

//*Send a batch statement in a connection
fn C.libsql_connection_info(self Libsql_connection_t) Libsql_connection_info_t

//*Send a batch statement in a transaction
fn C.libsql_transaction_batch(self Libsql_transaction_t, const_sql &char) Libsql_batch_t

//*Prepare a statement in a connection
fn C.libsql_connection_prepare(self Libsql_connection_t, const_sql &char) Libsql_statement_t

//*Prepare a statement in a transaction
fn C.libsql_transaction_prepare(self Libsql_transaction_t, const_sql &char) Libsql_statement_t

//*Execute a statement
fn C.libsql_statement_execute(self Libsql_statement_t) Libsql_execute_t

//*Query a statement
fn C.libsql_statement_query(self Libsql_statement_t) Libsql_rows_t

//*Reset a statement
fn C.libsql_statement_reset(self Libsql_statement_t)

//*Get the next row from rows
fn C.libsql_rows_next(self Libsql_rows_t) Libsql_row_t

//*Get the column name at the index
fn C.libsql_rows_column_name(self Libsql_rows_t, index int) Libsql_slice_t

//*Get rows column count
fn C.libsql_rows_column_length(self Libsql_rows_t) int

//*Get the value at the the index
fn C.libsql_row_value(self Libsql_row_t, index int) Libsql_result_value_t

//*Get the column name at the the index
fn C.libsql_row_name(self Libsql_row_t, index int) Libsql_slice_t

//*Get row column count
fn C.libsql_row_length(self Libsql_row_t) int

//*Check if the row is empty, indicating the end of `libsql_rows_next`
fn C.libsql_row_empty(self Libsql_row_t) bool

//*Bind a named argument to a statement
fn C.libsql_statement_bind_named(self Libsql_statement_t, const_name &char, value Libsql_value_t) Libsql_bind_t

//*Bind a positional argument to a statement
fn C.libsql_statement_bind_value(self Libsql_statement_t, value Libsql_value_t) Libsql_bind_t

//*Create a libsql integer value
fn C.libsql_integer(integer i64) Libsql_value_t

//*Create a libsql real value
fn C.libsql_real(real f64) Libsql_value_t

//*Create a libsql text value
fn C.libsql_text(const_ptr &char, len usize) Libsql_value_t

//*Create a libsql blob value
fn C.libsql_blob(const_ptr &u8, len usize) Libsql_value_t

//*Create a libsql null value
fn C.libsql_null() Libsql_value_t

//*Deallocate and close a error
fn C.libsql_error_deinit(self &Libsql_error_t)

//*Deallocate and close a database
fn C.libsql_database_deinit(self Libsql_database_t)

//*Deallocate and close a connection
fn C.libsql_connection_deinit(self Libsql_connection_t)

//*Deallocate and close a statement
fn C.libsql_statement_deinit(self Libsql_statement_t)

//*Deallocate and commit a transaction (transaction becomes invalid)
fn C.libsql_transaction_commit(self Libsql_transaction_t)

//*Deallocate and rollback a transaction (transaction becomes invalid)
fn C.libsql_transaction_rollback(self Libsql_transaction_t)

//*Deallocate and close rows
fn C.libsql_rows_deinit(self Libsql_rows_t)

//*Deallocate and close a row
fn C.libsql_row_deinit(self Libsql_row_t)

//*Deallocate a slice
fn C.libsql_slice_deinit(value Libsql_slice_t)

@[heap]
pub struct DB {
mut:
	conn C.libsql_connection_t
	db   C.libsql_database_t
}

struct Transaction {
mut:
	transaction C.libsql_transaction_t
}

struct Statement {
mut:
	statement C.libsql_statement_t
}

struct Rows {
	rows C.libsql_rows_t
}

struct Row {
	row C.libsql_row_t
}

struct Info {
	last_inserted_rowid i64
	total_changes       u64
}

// struct LibsqlError {
// 	Error
// 	libsql_error &C.libsql_error_t
// }

// pub fn (err LibsqlError) msg() string {
// 	unsafe {
// 		return cstring_to_vstring(C.libsql_error_message(err.libsql_error))
// 	}
// }

// @[unsafe]
// pub fn (mut err LibsqlError) free() {
// 	C.libsql_error_deinit(err.libsql_error)
// 	unsafe {
// 		free(err)
// 	}
// }

@[params]
pub struct Config {
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

fn create_desc(conf Config) Libsql_database_desc_t {
	mut libsql_desc := Libsql_database_desc_t{
		// url:  &char(conf.url.str)
		// path: &char(conf.path.str)
		// auth_token:               &char(conf.auth_token.str)
		// encryption_key:           &char(conf.encryption_key.str)
		// sync_interval:            conf.sync_interval
		// webpki:                   conf.webpki
		// disable_read_your_writes: conf.disable_read_your_writes
		// cypher:                   conf.cypher
	}
	// println(libsql_desc)
	if conf.url.len > 0 {
		libsql_desc.url = &char(conf.url.str)
	}
	if conf.path.len > 0 {
		libsql_desc.path = &char(conf.path.str)
	}
	if conf.auth_token.len > 0 {
		libsql_desc.auth_token = &char(conf.auth_token.str)
	}
	if conf.encryption_key.len > 0 {
		libsql_desc.encryption_key = &char(conf.encryption_key.str)
	}
	if conf.sync_interval > 0 {
		libsql_desc.sync_interval = conf.sync_interval
	}
	if conf.webpki {
		libsql_desc.webpki = conf.webpki
	}
	if conf.disable_read_your_writes {
		libsql_desc.disable_read_your_writes = conf.disable_read_your_writes
	}

	if conf.cypher != Libsql_cypher_t.default {
		libsql_desc.cypher = int(conf.cypher)
	}

	return libsql_desc
}

pub fn connect(conf Config) !DB {
	libsql_desc := create_desc(conf)
	db := C.libsql_database_init(libsql_desc)
	if !isnil(db.err) {
		println('unable to create a database')
		return libsql_error(db.err)
	}
	conn := C.libsql_database_connect(db)
	if !isnil(conn.err) {
		println('unable to connect to the database')
		return libsql_error(conn.err)
	}
	database := DB{
		conn: conn
		db:   db
	}
	// println(database)
	return database
}

@[unsafe]
pub fn (mut db DB) free() {
	C.libsql_connection_deinit(db.conn)
	C.libsql_database_deinit(db.db)
	unsafe {
		free(db)
	}
}

pub fn (db DB) info() !Info {
	info := C.libsql_connection_info(db.conn)
	if isnil(info.err) {
		return Info{
			last_inserted_rowid: info.last_inserted_rowid
			total_changes:       info.total_changes
		}
	}
	return libsql_error(info.err)
}

// Prepare a statement in a connection
pub fn (db DB) prepare(_sql string) !Statement {
	stmt := C.libsql_connection_prepare(db.conn, &char(_sql.str))
	if isnil(stmt.err) {
		return Statement{
			statement: stmt
		}
	}
	return libsql_error(stmt.err)
}

// Send a batch statement in a connection
pub fn (db DB) batch(_sql string) ! {
	stmt := C.libsql_connection_batch(db.conn, &char(_sql.str))
	if isnil(stmt.err) {
		return
	}
	return libsql_error(stmt.err)
}

// Begin a transaction
pub fn (db DB) transaction() !Transaction {
	t := C.libsql_connection_transaction(db.conn)
	if isnil(t.err) {
		return Transaction{
			transaction: t
		}
	}
	return libsql_error(t.err)
}

struct Sync {
	frame_no      u64
	frames_synced u64
}

// Sync frames with the primary
pub fn (db DB) sync() !Sync {
	sync := C.libsql_database_sync(db.db)
	if isnil(sync.err) {
		return Sync{
			frame_no:      sync.frame_no
			frames_synced: sync.frames_synced
		}
	}
	return libsql_error(sync.err)
}

// Transaction

@[unsafe]
pub fn (mut tx Transaction) free() {
	tx.commit()
	unsafe {
		free(tx)
	}
}

// Deallocate and commit a transaction (transaction becomes invalid)
pub fn (tx Transaction) commit() {
	C.libsql_transaction_commit(tx.transaction)
}

// Deallocate and rollback a transaction (transaction becomes invalid)
pub fn (tx Transaction) rollback() {
	C.libsql_transaction_rollback(tx.transaction)
}

// Prepare a statement in a transaction
pub fn (tx Transaction) prepare(_sql string) !Statement {
	stmt := C.libsql_transaction_prepare(tx.transaction, &char(_sql.str))
	if isnil(stmt.err) {
		return Statement{
			statement: stmt
		}
	}
	return libsql_error(stmt.err)
}

// Send a batch statement in a transaction
pub fn (tx Transaction) batch(_sql string) ! {
	stmt := C.libsql_transaction_batch(tx.transaction, &char(_sql.str))
	if isnil(stmt.err) {
		return
	}
	return libsql_error(stmt.err)
}

// Begin a transa

// Statement

@[unsafe]
pub fn (mut stmt Statement) free() {
	C.libsql_statement_deinit(stmt.statement)
	unsafe {
		free(stmt)
	}
}

// Execute a statement
pub fn (stmt Statement) execute() !u64 {
	execute := C.libsql_statement_execute(stmt.statement)
	if isnil(execute.err) {
		return execute.rows_changed
	}
	return libsql_error(execute.err)
}

// Query a statement
pub fn (stmt Statement) query() !Rows {
	rows := C.libsql_statement_query(stmt.statement)
	if isnil(rows.err) {
		return Rows{
			rows: rows
		}
	}
	return libsql_error(rows.err)
}

// Reset a statement
pub fn (stmt Statement) reset() {
	C.libsql_statement_reset(stmt.statement)
}

// Bind a named argument to a statement
pub fn (stmt Statement) bind_named(name string, val Libsql_value_t) ! {
	res := C.libsql_statement_bind_named(stmt.statement, &char(name.str), val)
	if isnil(res.err) {
		return
	}
}

// Bind a positional argument to a statement
pub fn (stmt Statement) bind_value(val Libsql_value_t) ! {
	res := C.libsql_statement_bind_value(stmt.statement, val)
	if isnil(res.err) {
		return
	}
}

// ROWS

@[unsafe]
pub fn (mut rows Rows) free() {
	C.libsql_rows_deinit(rows.rows)
	unsafe {
		free(rows)
	}
}

// Get the next row from rows
pub fn (mut rows Rows) next() ?Row {
	// row := C.libsql_rows_next(rows.rows)
	row := Row{
		row: C.libsql_rows_next(rows.rows)
	}
	if row.empty() {
		return none
	}
	if !isnil(row.row.err) {
		return none
	}
	return row
}

// Get the column name at the index
pub fn (mut rows Rows) column_name(index int) string {
	row := C.libsql_rows_column_name(rows.rows, index)
	unsafe {
		return cstring_to_vstring(row.ptr)
	}
}

// Get rows column count
pub fn (mut rows Rows) column_length() int {
	return C.libsql_rows_column_length(rows.rows)
}

// Row

@[unsafe]
pub fn (mut row Row) free() {
	C.libsql_row_deinit(row.row)
	unsafe {
		free(row)
	}
}

// Get the value at the the index
pub fn (row Row) value(index int) !Libsql_value_t {
	value := C.libsql_row_value(row.row, index)
	if isnil(value.err) {
		return value.ok
	}
	return libsql_error(value.err)
}

// Get the column name at the the index
pub fn (row Row) name(index int) string {
	name := C.libsql_row_name(row.row, index)
	unsafe {
		return cstring_to_vstring(name.ptr)
	}
}

// Get row column count
pub fn (row Row) length() int {
	return C.libsql_row_length(row.row)
}

// Check if the row is empty, indicating the end of `Rows.next()`
pub fn (row Row) empty() bool {
	return C.libsql_row_empty(row.row)
}

// VALUES

pub fn integer(i i64) Libsql_value_t {
	return C.libsql_integer(i)
}

pub fn real(f f64) Libsql_value_t {
	return C.libsql_real(f)
}

pub fn text(s string) Libsql_value_t {
	return C.libsql_text(&char(s.str), s.len)
}

pub fn blob(b []u8) Libsql_value_t {
	return C.libsql_blob(&b[0], b.len)
}

pub fn null() Libsql_value_t {
	return C.libsql_null()
}

// UTILS

pub fn setup(config Libsql_config_t) ! {
	err := C.libsql_setup(config)
	if isnil(err) {
		return
	}
	return libsql_error(err)
}

fn libsql_error(err &Libsql_error_t) IError {
	defer {
		C.libsql_error_deinit(err)
	}
	unsafe {
		return error(cstring_to_vstring(C.libsql_error_message(err)))
	}
}
