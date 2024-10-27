module main

import vlibsql

@[table: 'users']
struct Users {
	id   int    @[primary; sql: serial]
	name string @[sql_type: 'TEXT']
	cats string @[sql_type: 'VARCHAR(255)']
}

fn main() {
	vlibsql.setup(vlibsql.Libsql_config_t{}) or { panic(err) }
	db := vlibsql.connect(path: 'local.db') or { panic(err) }
	defer {
		unsafe {
			db.free()
		}
	}

	setup_sql := "
	DROP TABLE IF EXISTS users;
	CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, cats TEXT);
	INSERT INTO users (name, cats) VALUES ('Iku Turso', 'three');
	"
	db.batch(setup_sql) or { panic(err) }

	mut all := sql db {
		select from Users
	}!

	assert all[0].name == 'Iku Turso'

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

	sql db {
		update Users set name = 'Coco Smith' where id == 1
	} or { panic(err) }

	all = sql db {
		select from Users
	}!

	assert all[0].id == 1

	sql db {
		delete from Users where id == 1
	} or { panic(err) }
}
