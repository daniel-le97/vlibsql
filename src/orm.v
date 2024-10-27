module vlibsql

import orm
// import time

fn statement_binder(stm Statement, data orm.QueryData) ! {
	for idx, name in data.fields {
		prim := data.data[idx]

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
			orm.InfixType {
				// TODO handle InfixType
				print('InfixType')
				null()
			}
			else {
				null()
			}
		}
		// if data.fields.len == 1 {
		// 	stm.bind_value(val) or { panic('unable to bind ${name}: ${err}') }
		// } else {
		stm.bind_named(':${name}', val) or { panic('unable to bind ${name}: ${err}') }
		// }
	}
}

fn query_converter(db DB, query string, query_data []orm.QueryData) !Statement {
	mut counter := 1
	mut new_query := query

	for data in query_data {
		for name in data.fields {
			new_query = new_query.replace(':${counter}', ':${name}')
			counter++
		}
	}

	$if trace_orm ? {
		eprintln('> vlibsql query: ${new_query}')
	}
	stmt := db.prepare(new_query)!
	for data in query_data {
		statement_binder(stmt, data) or { panic(err) }
	}

	return stmt
}

// select is used internally by V's ORM for processing `SELECT` queries
pub fn (db DB) select(config orm.SelectConfig, data orm.QueryData, where orm.QueryData) ![][]orm.Primitive {
	// 1. Create query and bind necessary data
	query := orm.orm_select_gen(config, '', true, ':', 1, where)
	stmt := query_converter(db, query, [data, where])!

	defer {
		unsafe {
			stmt.free()
		}
	}

	rows := stmt.query() or {
		panic('${@FILE} unable to execute select query: ${query}, error: ${err}')
	}
	mut ret := [][]orm.Primitive{}
	for row in rows {
		mut prim := []orm.Primitive{}
		cols := row.length()
		for i in 0 .. cols {
			val := row.value(i)!
			val_type := get_value_type(val.type)
			pri := match val_type {
				.text {
					unsafe {
						orm.Primitive(cstring_to_vstring(val.value.text.ptr))
					}
				}
				.integer {
					unsafe {
						orm.Primitive(int(val.value.integer))
					}
				}
				.real {
					unsafe {
						f64(val.value.real)
					}
				}
				// .blob
				else {
					orm.null_primitive
				}
			}
			// println(typeof[pri]())
			// print(pri)
			prim << pri
		}
		ret << prim
	}

	return ret
}

// insert is used internally by V's ORM for processing `INSERT` queries
pub fn (db DB) insert(table string, data orm.QueryData) ! {
	_, converted_data := orm.orm_stmt_gen(.sqlite, table, '', .insert, false, '?', 1,
		data, orm.QueryData{})

	// libsql expects sql like: UPDATE users SET name = :name WHERE id = :id;
	query := 'INSERT INTO ${table} (${converted_data.fields.join(', ')}) VALUES (:${converted_data.fields.join(', :')});'

	stmt := db.prepare(query)!

	defer {
		unsafe {
			stmt.free()
		}
	}
	statement_binder(stmt, converted_data) or { panic(err) }
	stmt.execute() or { panic('${@FILE} unable execute query: ${query}, error: ${err}') }
}

// update is used internally by V's ORM for processing `UPDATE` queries
pub fn (db DB) update(table string, data orm.QueryData, where orm.QueryData) ! {
	mut query, _ := orm.orm_stmt_gen(.sqlite, table, '', .update, true, ':', 1, data,
		where)

	// turn UPDATE users SET name = ?1 WHERE id = ?2;
	// into UPDATE users SET name = :name WHERE id = :id;
	stmt := query_converter(db, query, [data, where])!
	defer {
		unsafe {
			stmt.free()
		}
	}

	stmt.execute() or { panic('${@FILE} unable execute query: ${query}, error: ${err}') }
}

// delete is used internally by V's ORM for processing `DELETE ` queries
pub fn (db DB) delete(table string, where orm.QueryData) ! {
	query, converted := orm.orm_stmt_gen(.sqlite, table, '', .delete, true, ':', 1, orm.QueryData{},
		where)

	stmt := query_converter(db, query, [converted, where])!
	defer {
		unsafe {
			stmt.free()
		}
	}

	stmt.execute() or { panic('${@FILE} unable execute query: ${query}, error: ${err}') }
}

// last_id is used internally by V's ORM for post-processing `INSERT` queries
pub fn (db DB) last_id() int {
	// query := 'SELECT last_insert_rowid();'
	last_insert_id, _ := db.info() or { panic(err) }
	return int(last_insert_id)
}

// DDL (table creation/destroying etc)
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
		for attr in field.attrs {
			if attr.name == 'primary' {
				for idx, str in field_strs {
					if str.starts_with('PRIMARY KEY') {
						field_strs.delete(idx)
					}

					if str.starts_with(field.name) && !str.contains('PRIMARY KEY') {
						field_strs[idx] = str + ' PRIMARY KEY'
					}
				}
			}
			if attr.name == 'sql' {
				if attr.arg == 'serial' {
					for idx, str in field_strs {
						if str.starts_with(field.name) && !str.contains('AUTOINCREMENT') {
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
		eprintln('> vlibsql orm drop: ${query}')
	}
	db.batch(query)!
}
