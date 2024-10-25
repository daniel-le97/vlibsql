module main

import vlibsql

fn main() {
	vlibsql.setup(vlibsql.Libsql_config_t{}) or { panic(err) }

	secret := 'my_secret_key'

	db := vlibsql.connect(
		path:           'encrypted.db'
		encryption_key: secret
		cypher:         .aes_256
	) or { panic(err) }

	defer {
		unsafe {
			db.free()
		}
	}
	setup_sql := "
	DROP TABLE IF EXISTS users;
	CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);
	INSERT INTO users (name) VALUES ('Iku Turso');
	"
	db.batch(setup_sql) or { panic(err) }
	forenames := ['John', 'Jane', 'Jack', 'Jill']
	surnames := ['Smith', 'Doe', 'Black', 'White']

	mut stmt := db.prepare('INSERT INTO users (name) VALUES (?)') or { panic(err) }
	defer {
		unsafe {
			stmt.free()
		}
	}
	for forename in forenames {
		for surname in surnames {
			fullname := forename + ' ' + surname
			stmt.reset()
			stmt.bind_value(vlibsql.text(fullname)) or { panic(err) }
			stmt.execute() or { panic(err) }
		}
	}

	query_stmt := db.prepare('SELECT * FROM users') or { panic(err) }
	defer {
		unsafe {
			query_stmt.free()
		}
	}

	rows := query_stmt.query() or { panic(err) }
	for row in rows {
		id_ptr := row.value(0) or { panic(err) }
		name_ptr := row.value(1) or { panic(err) }
		unsafe {
			id := id_ptr.value.integer
			name := name_ptr.value.text.ptr
			println('id: ${id}')
			println('name: ${cstring_to_vstring(name)}')
			row.free()
		}
	}
	unsafe {
		rows.free()
	}

	println('Database is now encrypted with AES-256')
}
