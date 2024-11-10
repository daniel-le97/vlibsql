module vlibsql

import orm
import time

// DDL (table creation/destroying etc)
fn sqlite_type_from_v(typ int) !string {
	return if typ in orm.nums || typ in orm.num64 || typ in [orm.serial, orm.time_, orm.enum_] {
		'INTEGER'
	} else if typ in orm.float {
		'REAL'
	} else if typ == orm.type_string {
		'TEXT'
	} else if typ == -2 {
		'TEXT'
	} else {
		error('Unknown type ${typ}')
	}
}

fn orm_primitive_to_libsql_value(prim orm.Primitive) !Libsql_value_t {
	return match prim {
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
			null()
			// null()
		}
		time.Time {
			text(prim.str())
		}
		else {
			null()
		}
	}
}

fn query_converter(db DB, query string, query_data []orm.QueryData) !Statement {
	mut counter := 1
	mut field_counter := 1
	mut new_query := query

	for data in query_data {
		for name in data.fields {
			if new_query.contains(':${name}') {
				// print('name: ${name}')
				new_query = new_query.replace(':${counter}', ':${name}_${field_counter}')
				field_counter++
				counter++
				continue
			}
			new_query = new_query.replace(':${counter}', ':${name}')
			counter++
		}
	}

	$if trace_orm ? {
		eprintln('> vlibsql query: ${new_query}')
	}
	// println(new_query)
	stmt := db.prepare(new_query)!

	mut bound_fields := []string{}
	field_counter = 1
	for data in query_data {
		for field_idx, field in data.fields {
			prim := data.data[field_idx]
			val := orm_primitive_to_libsql_value(prim)!
			if field in bound_fields {
				stmt.bind_named(':${field}_${field_counter}', val)!
				field_counter++
			} else {
				stmt.bind_named(':${field}', val)!
			}
			bound_fields << field
		}
		// statement_binder(stmt, data) or { panic(err) }
	}

	return stmt
}

fn libsql_value_to_orm_primitive(type_idx int, value Libsql_value_t) !orm.Primitive {
	if type_idx == 5 {
		return unsafe { i8(value.value.integer) }
	}
	if type_idx == 6 {
		return unsafe { i16(value.value.integer) }
	}
	if type_idx == 8 {
		return unsafe { int(value.value.integer) }
	}
	if type_idx == 9 {
		return unsafe { i64(value.value.integer) }
	}
	if type_idx == 11 {
		return unsafe { u8(value.value.integer) }
	}
	if type_idx == 12 {
		return unsafe { u16(value.value.integer) }
	}
	if type_idx == 13 {
		return unsafe { u32(value.value.integer) }
	}
	if type_idx == 14 {
		return unsafe { u64(value.value.integer) }
	}

	if type_idx == 16 {
		return f32(unsafe { value.value.real })
	}
	if type_idx == 17 {
		return unsafe { value.value.real }
	}
	if type_idx == -2 {
		return time.parse(unsafe { cstring_to_vstring(value.value.text.ptr) })!
	}

	if type_idx == 19 {
		vl := unsafe { int(value.value.integer) }
		if vl == 0 {
			return false
		} else {
			return true
		}
	}

	if type_idx == 21 {
		return unsafe { cstring_to_vstring(value.value.text.ptr) }
	}
	return orm.null_primitive
}

fn get_primitives_from_rows(rows Rows, type_idxs []int) ![][]orm.Primitive {
	mut ret := [][]orm.Primitive{}
	for row in rows {
		mut prim := []orm.Primitive{}
		cols := row.length()
		for i in 0 .. cols {
			val := row.value(i)!
			conf_type := type_idxs[i]
			prim << libsql_value_to_orm_primitive(conf_type, val)!
		}
		ret << prim
	}

	return ret
}

// select is used internally by V's ORM for processing `SELECT` queries
pub fn (db DB) select(config orm.SelectConfig, data orm.QueryData, where orm.QueryData) ![][]orm.Primitive {
	// 1. Create query and bind necessary data
	// println(data)
	// println(config)
	mut query := orm.orm_select_gen(config, '', true, ':', 1, where)

	if data.data.len == 0 && where.data.len == 0 {
		query = query.replace('IS NULL', 'IS :null')
		ex := db.prepare(query)!
		defer {
			unsafe {
				ex.free()
			}
		}
		ex.bind_value(null())!
		bl := ex.query()!
		return get_primitives_from_rows(bl, config.types) or { [] }
	}
	// println(query)
	stmt := query_converter(db, query, [data, where])!
	// println(query)
	defer {
		unsafe {
			stmt.free()
		}
	}

	rows := stmt.query() or {
		panic('${@FILE} unable to execute select query: ${query}, error: ${err}')
	}
	return get_primitives_from_rows(rows, config.types) or { [] }
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

	for idx, name in converted_data.fields {
		prim := converted_data.data[idx]
		val := orm_primitive_to_libsql_value(prim)!
		stmt.bind_named(':${name}', val) or { panic('unable to bind ${name}: ${err}') }
	}
	stmt.execute() or { panic('${@FILE} unable to execute query: ${query}, error: ${err}') }
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

	stmt.execute() or { panic('${@FILE} unable to execute query: ${query}, error: ${err}') }
}

// last_id is used internally by V's ORM for post-processing `INSERT` queries
pub fn (db DB) last_id() int {
	// query := 'SELECT last_insert_rowid();'
	last_insert_id, _ := db.info() or { panic(err) }
	return int(last_insert_id)
}

// create is used internally by V's ORM for processing table creation queries (DDL)
pub fn (db DB) create(table string, fields []orm.TableField) ! {
	mut query := orm.orm_table_gen(table, '', true, 0, fields, sqlite_type_from_v, false) or {
		return err
	}

	// println(fields)
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
