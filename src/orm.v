module vlibsql

import orm
// import time

// select is used internally by V's ORM for processing `SELECT ` queries
pub fn (db DB) select(config orm.SelectConfig, data orm.QueryData, where orm.QueryData) ![][]orm.Primitive {
	// 1. Create query and bind necessary data
	query := orm.orm_select_gen(config, '`', true, '?', 1, where)
	println(query)
	// $if trace_sqlite ? {
	// 	eprintln('> select query: "${query}"')
	// }
	// stmt := db.new_init_stmt(query)!
	// defer {
	// 	stmt.finalize()
	// }
	// mut c := 1
	// sqlite_stmt_binder(stmt, where, query, mut c)!
	// sqlite_stmt_binder(stmt, data, query, mut c)!

	mut ret := [][]orm.Primitive{}

	// if config.is_count {
	// 	// 2. Get count of returned values & add it to ret array
	// 	step := stmt.step()
	// 	if step !in [sqlite_row, sqlite_field_strs, sqlite_done] {
	// 		return db.error_message(step, query)
	// 	}
	// 	count := stmt.sqlite_select_column(0, 8)!
	// 	ret << [count]
	// 	return ret
	// }
	// for {
	// 	// 2. Parse returned values
	// 	step := stmt.step()
	// 	if step == sqlite_done {
	// 		break
	// 	}
	// 	if step != sqlite_field_strs && step != sqlite_row {
	// 		break
	// 	}
	// 	mut row := []orm.Primitive{}
	// 	for i, typ in config.types {
	// 		primitive := stmt.sqlite_select_column(i, typ)!
	// 		row << primitive
	// 	}
	// 	ret << row
	// }
	return ret
}

// sql stmt

// insert is used internally by V's ORM for processing `INSERT ` queries
pub fn (db DB) insert(table string, data orm.QueryData) ! {
	println('Insert:')
	_, converted_data := orm.orm_stmt_gen(.sqlite, table, '', .insert, false, '?', 1,
		data, orm.QueryData{})

	query := 'INSERT INTO ${table} (${converted_data.fields.join(', ')}) VALUES (:${converted_data.fields.join(', :')});'

	stmt := db.prepare(query)!

	defer {
		unsafe {
			stmt.free()
		}
	}

	for idx, name in converted_data.fields {
		prim := converted_data.data[idx]

		val := match prim {
			i8, i16, int, u8, u16, u32, bool, i64, u64 {
				integer(i64(prim))
			}
			f32, f64 {
				real(f64(prim))
			}
			string {
				text(string(prim))
			}
			// orm.InfixType {
			// 	integer(i64(prim.right))

			// }
			else {
				null()
			}
		}
		if converted_data.fields.len == 1 {
			stmt.bind_value(val) or { panic('unable to bind ${name}: ${err}') }
		} else {
			stmt.bind_named(':${name}', val) or { panic('unable to bind ${name}: ${err}') }
		}
	}

	stmt.execute() or { panic('${@FILE} unable execute query: ${query}, error: ${err}') }
}

// update is used internally by V's ORM for processing `UPDATE ` queries
pub fn (db DB) update(table string, data orm.QueryData, where orm.QueryData) ! {
	query, _ := orm.orm_stmt_gen(.sqlite, table, '`', .update, true, '?', 1, data, where)
	println(query)
	// sqlite_stmt_worker(db, query, data, where)!
}

// delete is used internally by V's ORM for processing `DELETE ` queries
pub fn (db DB) delete(table string, where orm.QueryData) ! {
	query, _ := orm.orm_stmt_gen(.sqlite, table, '`', .delete, true, '?', 1, orm.QueryData{},
		where)

	println(query)
	// sqlite_stmt_worker(db, query, orm.QueryData{}, where)!
}

// last_id is used internally by V's ORM for post-processing `INSERT ` queries
pub fn (db DB) last_id() int {
	// query := 'SELECT last_insert_rowid();'
	last_insert_id, _ := db.info() or { panic(err) }
	return int(last_insert_id)
	// return db.q_int(query) or { 0 }
}

// // DDL (table creation/destroying etc)

fn sqlite_type_from_v(typ int) !string {
	return if typ in orm.nums || typ in orm.num64 || typ in [orm.serial, orm.time_, orm.enum_] {
		'INTEGER'
	} else if typ in orm.float {
		'REAL'
	} else if typ == orm.type_string {
		'TEXT'
	} else {
		error('Unknown type ${typ}')
	}
}

// create is used internally by V's ORM for processing table creation queries (DDL)
pub fn (db DB) create(table string, fields []orm.TableField) ! {
	mut query := orm.orm_table_gen(table, '', true, 0, fields, sqlite_type_from_v, false) or {
		return err
	}
	// has := 0
	sep := 'CREATE TABLE IF NOT EXISTS ${table} '
	mut field_strs := query.after(sep).find_between('(', ');').split(', ')

	// rewrites CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT NOT NULL, PRIMARY KEY(id)); into
	// CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL);
	for field in fields {
		// println(field)
		for attr in field.attrs {
			if attr.name == 'primary' {
				for idx, str in field_strs {
					if str.starts_with('PRIMARY KEY') {
						field_strs.delete(idx)
					}

					if str.starts_with(field.name) {
						field_strs[idx] = str + ' PRIMARY KEY'
					}
				}
			}
			if attr.name == 'sql' {
				if attr.arg == 'serial' {
					for idx, str in field_strs {
						if str.starts_with(field.name) {
							field_strs[idx] = str + ' AUTOINCREMENT'
						}
					}
				}
			}
			// break
		}
	}

	stmt := '${sep}(${field_strs.join(', ')});'
	// for idx, str in field_strs {
	$if trace_orm ? {
		eprintln('> vlibsql orm create: ${stmt}')
	}
	db.batch(stmt)!
}

// drop is used internally by V's ORM for processing table destroying queries (DDL)
pub fn (db DB) drop(table string) ! {
	query := 'DROP TABLE IF EXISTS ${table};'
	$if trace_orm ? {
		eprintln('> vlibsql orm drop: ${stmt}')
	}
	db.batch(query)!
}

// // helper

// // Executes query and bind prepared statement data directly
// fn sqlite_stmt_worker(db DB, query string, data orm.QueryData, where orm.QueryData) ! {
// 	$if trace_sqlite ? {
// 		eprintln('> sqlite_stmt_worker query: "${query}"')
// 	}
// 	stmt := db.new_init_stmt(query)!
// 	defer {
// 		stmt.finalize()
// 	}
// 	mut c := 1
// 	sqlite_stmt_binder(stmt, data, query, mut c)!
// 	sqlite_stmt_binder(stmt, where, query, mut c)!
// 	stmt.orm_step(query)!
// }

// // Binds all values of d in the prepared statement
// fn sqlite_stmt_binder(stmt Stmt, d orm.QueryData, query string, mut c &int) ! {
// 	for data in d.data {
// 		err := bind(stmt, c, data)

// 		if err != 0 {
// 			return stmt.db.error_message(err, query)
// 		}
// 		c++
// 	}
// }

// // Universal bind function
// fn bind(stmt Stmt, c &int, data orm.Primitive) int {
// 	mut err := 0
// 	match data {
// 		i8, i16, int, u8, u16, u32, bool {
// 			err = stmt.bind_int(c, int(data))
// 		}
// 		i64, u64 {
// 			err = stmt.bind_i64(c, i64(data))
// 		}
// 		f32, f64 {
// 			err = stmt.bind_f64(c, unsafe { *(&f64(&data)) })
// 		}
// 		string {
// 			err = stmt.bind_text(c, data)
// 		}
// 		time.Time {
// 			err = stmt.bind_int(c, int(data.unix()))
// 		}
// 		orm.InfixType {
// 			err = bind(stmt, c, data.right)
// 		}
// 		orm.Null {
// 			err = stmt.bind_null(c)
// 		}
// 	}
// 	return err
// }

// // Selects column in result and converts it to an orm.Primitive
// fn (stmt Stmt) sqlite_select_column(idx int, typ int) !orm.Primitive {
// 	if typ in orm.nums || typ == -1 {
// 		return stmt.get_int(idx) or { return orm.Null{} }
// 	} else if typ in orm.num64 {
// 		return stmt.get_i64(idx) or { return orm.Null{} }
// 	} else if typ in orm.float {
// 		return stmt.get_f64(idx) or { return orm.Null{} }
// 	} else if typ == orm.type_string {
// 		if v := stmt.get_text(idx) {
// 			return v.clone()
// 		} else {
// 			return orm.Null{}
// 		}
// 	} else if typ == orm.enum_ {
// 		return stmt.get_i64(idx) or { return orm.Null{} }
// 	} else if typ == orm.time_ {
// 		if v := stmt.get_int(idx) {
// 			return time.unix(v)
// 		} else {
// 			return orm.Null{}
// 		}
// 	} else {
// 		return error('Unknown type ${typ}')
// 	}
// }
