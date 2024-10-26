module main

import vlibsql
import os
import time

fn main() {
	env_path := '${@VMODROOT}/.env'
	load_env(env_path, false)
	libsql_url := os.getenv('LIBSQL_URL')
	libsql_auth_token := os.getenv('LIBSQL_AUTH_TOKEN')

	if libsql_auth_token.len == 0 {
		panic('LIBSQL_AUTH_TOKEN is not set in ${env_path}')
	}

	if libsql_url.len == 0 {
		panic('LIBSQL_URL is not set in ${env_path}')
	}

	vlibsql.setup(vlibsql.Libsql_config_t{}) or { panic(err) }

	db := vlibsql.connect(
		url:           libsql_url
		path:          'sync.db'
		auth_token:    libsql_auth_token
		// sync_interval: 60000
	) or { panic(err) }

	defer {
		unsafe {
			db.free()
		}
	}

	setup_sql := "
	CREATE TABLE IF NOT EXISTS sync_test (id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT);
	INSERT INTO sync_test (value) VALUES ('Initial value');
	"
	db.batch(setup_sql) or { panic(err) }

	println('Inital data insterted. Waiting for sync...')

	time.sleep(15)

	synced := db.sync() or { panic(err) }

	println('Manual sync completed. Frame number: ${synced.frame_no}, Frames synched ${synced.frames_synced}')

	db.batch("INSERT INTO sync_test (value) VALUES ('New value after sync');") or { panic(err) }

	println('New data insterted.')
	query_stmt := db.prepare('SELECT * FROM sync_test') or { panic(err) }
	defer {
		unsafe {
			query_stmt.free()
		}
	}

	println('Current Data in sync_test table:')
	rows := query_stmt.query() or { panic(err) }
	for row in rows {
		id_ptr := row.value(0) or { panic(err) }
		value_ptr := row.value(1) or { panic(err) }
		unsafe {
			id := id_ptr.value.integer
			val := value_ptr.value.text.ptr
			println('${id}: ${cstring_to_vstring(val)}')
		}
	}
}

fn load_env(path string, overwrite bool) {
	str := os.read_lines(path) or { panic(err) }
	for line in str {
		// Skip empty lines and comments
		env := line.split('=')
		key := env[0]
		value := env[1]
		os.setenv(key, value, overwrite)
	}
}
