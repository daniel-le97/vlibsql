module main

import vlibsql

@[table: 'users']
struct Users {
	id   ?int   @[primary; sql: serial]
	name string @[sql_type: 'TEXT']
	cats string	@[sql_type: 'TEXT']
}

fn main() {
	vlibsql.setup(vlibsql.Libsql_config_t{}) or { panic(err) }
	db := vlibsql.connect(path: 'local.db') or { panic(err) }
	defer {
		unsafe {
			db.free()
		}
	}
	// setup_sql := "
	// DROP TABLE IF EXISTS users;
	// CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);
	// INSERT INTO users (name) VALUES ('Iku Turso');
	// "
	// db.batch(setup_sql) or { panic(err) }
	sql db {
		drop table Users
	} or { panic(err) }
	sql db {
		create table Users
	} or { panic(err) }

	usr := Users{
		name: 'Iku Turso'
		cats: 'three'
	}
	// println(usr)
	sql db {
		insert usr into Users
	} or { panic(err) }
}
