module vlibsql

import orm
import time
import os

const db_path = 'orm_test.db'

@[table: 'testcustomsql']
struct TestCustomSqlType {
	id      int    @[primary; sql: serial]
	custom  string @[sql_type: 'TEXT']
	custom1 string @[sql_type: 'VARCHAR(191)']
	custom2 string @[sql_type: 'datetime(3)']
	custom3 string @[sql_type: 'MEDIUMINT']
	custom4 string @[sql_type: 'DATETIME']
	custom5 string @[sql_type: 'datetime']
}

struct TestCustomWrongSqlType {
	id      int @[primary; sql: serial]
	custom  string
	custom1 string @[sql_type: 'VARCHAR']
	custom2 string @[sql_type: 'money']
	custom3 string @[sql_type: 'xml']
}

struct TestTimeType {
mut:
	id         int @[primary; sql: serial]
	username   string
	created_at time.Time @[sql_type: 'DATETIME']
	updated_at string    @[sql_type: 'DATETIME']
	deleted_at time.Time
}

struct TestDefaultAttribute {
	id         int @[primary; sql: serial]
	name       string
	created_at string @[default: 'CURRENT_TIMESTAMP'; sql_type: 'TIMESTAMP']
}

fn test_vlibsql_orm() {
	setup(Libsql_config_t{}) or { panic(err) }
	db := connect(path: 'orm_test.db') or { panic(err) }
	defer {
		unsafe {
			db.free()
		}
	}

	sql db {
		create table TestDefaultAttribute
	}!

	default_attr := TestDefaultAttribute{
		name: 'daniel'
	}
	sql db {
		insert default_attr into TestDefaultAttribute
	}!

	sql db {
		update TestDefaultAttribute set name = 'Coco Smith' where id == 1
	} or { panic(err) }

	all := sql db {
		select from TestDefaultAttribute
	}!

	// println(all)

	db.create('Test', [
		orm.TableField{
			name:  'id'
			typ:   typeof[int]().idx
			attrs: [
				VAttribute{
					name: 'primary'
				},
				VAttribute{
					name:    'sql'
					has_arg: true
					kind:    .plain
					arg:     'serial'
				},
			]
		},
		orm.TableField{
			name:  'name'
			typ:   typeof[string]().idx
			attrs: []
		},
		orm.TableField{
			name: 'age'
			typ:  typeof[int]().idx
		},
	]) or { panic(err) }

	db.insert('Test', orm.QueryData{
		fields: ['name', 'age']
		data:   [orm.string_to_primitive('Louis'), orm.int_to_primitive(101)]
	}) or { panic(err) }

	res := db.select(orm.SelectConfig{
		table:     'Test'
		has_where: true
		fields:    ['id', 'name', 'age']
		types:     [typeof[int]().idx, typeof[string]().idx, typeof[i64]().idx]
	}, orm.QueryData{}, orm.QueryData{
		fields: ['name', 'age']
		data:   [orm.Primitive('Louis'), i64(101)]
		types:  [typeof[string]().idx, typeof[i64]().idx]
		is_and: [true, true]
		kinds:  [.eq, .eq]
	}) or { panic(err) }

	id_ := res[0][0]
	name := res[0][1]
	age := res[0][2]

	assert id_ is int
	if id_ is int {
		assert id_ == 1
	}

	assert name is string
	if name is string {
		assert name == 'Louis'
	}

	assert age is i64
	if age is i64 {
		assert age == 101
	}
}

struct TestOrmValuesOne {
	an_f32 f32 // REAL
	an_f64 f64 // REAL
	an_i16 i16 // INTEGER
	an_i64 i64 // INTEGER
}

struct TestOrmValuesTwo {
	an_i8    i8     // INTEGER
	an_int   int    // INTEGER
	a_string string // TEXT
}

struct TestOrmValuesThree {
	an_u16 u16 // INTEGER
	an_u32 u32 // INTEGER
	an_u64 u64 // INTEGER
	an_u8  u8  // INTEGER
}

struct TestOrmValuesFour {
	a_time      time.Time // TEXT
	a_bool      bool      // INTEGER
	int_or_null ?int      // INTEGER ( NULLABLE )
}

fn test_default_orm_values() {
	setup(Libsql_config_t{}) or { panic(err) }
	db := connect(path: ':memory:') or { panic(err) }
	defer {
		unsafe {
			db.free()
		}
	}

	mut error := ''
	sql db {
		create table TestOrmValuesOne
		create table TestOrmValuesTwo
		create table TestOrmValuesThree
		create table TestOrmValuesFour
	} or { error = err.str() }
	assert error == ''

	values_one := TestOrmValuesOne{
		an_f32: 3.14
		an_f64: 2.718281828459
		an_i16: 12345
		an_i64: 123456789012345
	}
	values_two := TestOrmValuesTwo{
		an_i8:    12
		an_int:   123456
		a_string: 'Hello, World!'
	}
	values_three := TestOrmValuesThree{
		an_u16: 54321
		an_u32: 1234567890
		an_u64: 1234
		an_u8:  255
	}

	values_four := TestOrmValuesFour{
		a_time: time.now()
		a_bool: true
		// int_or_null: 123
	}
	values_four_b := TestOrmValuesFour{
		a_time:      time.now()
		a_bool:      false
		int_or_null: 123
	}

	sql db {
		insert values_one into TestOrmValuesOne
		insert values_two into TestOrmValuesTwo
		insert values_three into TestOrmValuesThree
		insert values_four into TestOrmValuesFour
		insert values_four_b into TestOrmValuesFour
	} or { error = err.str() }

	assert error == ''
	// println(error)

	result_values_one := sql db {
		select from TestOrmValuesOne
	}!
	one := result_values_one[0]

	// println(orm.type_idx)

	assert typeof(one.an_f32).idx == typeof[f32]().idx
	assert one.an_f32 == 3.14
	assert typeof(one.an_f64).idx == typeof[f64]().idx
	assert one.an_f64 == 2.718281828459
	assert typeof(one.an_i16).idx == typeof[i16]().idx
	assert one.an_i16 == 12345
	assert typeof(one.an_i64).idx == typeof[i64]().idx
	assert one.an_i64 == 123456789012345

	result_values_two := sql db {
		select from TestOrmValuesTwo
	}!

	two := result_values_two[0]

	assert typeof(two.an_i8).idx == typeof[i8]().idx
	assert two.an_i8 == 12
	assert typeof(two.an_int).idx == typeof[int]().idx
	assert two.an_int == 123456
	assert typeof(two.a_string).idx == typeof[string]().idx
	assert two.a_string == 'Hello, World!'

	result_values_three := sql db {
		select from TestOrmValuesThree
	}!

	three := result_values_three[0]

	assert typeof(three.an_u16).idx == typeof[u16]().idx
	assert three.an_u16 == 54321
	assert typeof(three.an_u32).idx == typeof[u32]().idx
	assert three.an_u32 == 1234567890
	// println(three.an_u64)
	assert typeof(three.an_u64).idx == typeof[u64]().idx
	assert three.an_u64 == 1234
	assert typeof(three.an_u8).idx == typeof[u8]().idx
	assert three.an_u8 == 255

	result_values_four := sql db {
		select from TestOrmValuesFour
	}!

	four := result_values_four[0]
	// println(result_values_four)
	assert typeof(four.a_time).idx == typeof[time.Time]().idx
	assert typeof(four.a_bool).idx == typeof[bool]().idx
	assert four.a_bool == true
	assert typeof(four.int_or_null).idx == typeof[?int]().idx
	unwrapped_option_one := four.int_or_null or { 0 }
	assert unwrapped_option_one == 0
	unwrapped_option_two := result_values_four[1].int_or_null or { 0 }
	assert unwrapped_option_two == 123
}

struct Product {
	id           int // @[primary] FIXME
	product_name string
	price        string //@[sql_type: 'INTEGER']
	quantity     ?i16
}

fn test_orm_select_where() {
	setup(Libsql_config_t{}) or { panic(err) }
	os.rm(db_path) or {}
	db := connect(path: db_path) or { panic(err) }
	defer {
		unsafe {
			db.free()
		}
	}
	mut error := ''

	sql db {
		create table Product
	} or { panic(err) }

	prods := [
		Product{1, 'Ice Cream', '5.99', 17},
		Product{2, 'Ham Sandwhich', '3.47', none},
		Product{3, 'Bagel', '1.25', 45},
	]
	for product in prods {
		sql db {
			insert product into Product
		} or { panic(err) }
	}
	mut products := sql db {
		select from Product where id == 2
	}!

	assert products == [Product{2, 'Ham Sandwhich', '3.47', none}]

	products = sql db {
		select from Product where id == 5
	}!

	assert products == []

	products = sql db {
		select from Product where id != 3
	}!

	assert products == [Product{1, 'Ice Cream', '5.99', 17},
		Product{2, 'Ham Sandwhich', '3.47', none}]

	products = sql db {
		select from Product where price > '3.47'
	}!

	assert products == [Product{1, 'Ice Cream', '5.99', 17}]

	products = sql db {
		select from Product where price >= '3'
	}!

	assert products == [Product{1, 'Ice Cream', '5.99', 17},
		Product{2, 'Ham Sandwhich', '3.47', none}]

	products = sql db {
		select from Product where price < '3.47'
	}!

	assert products == [Product{3, 'Bagel', '1.25', 45}]

	products = sql db {
		select from Product where price <= '5'
	}!

	assert products == [Product{2, 'Ham Sandwhich', '3.47', none},
		Product{3, 'Bagel', '1.25', 45}]

	// // // TODO (daniel-le97): The ORM does not support a "not like" constraint right now.

	products = sql db {
		select from Product where product_name like 'Ham%'
	}!

	assert products == [Product{2, 'Ham Sandwhich', '3.47', none}]

	products = sql db {
		select from Product where quantity is none
	}!

	// println(products)

	assert products == [Product{2, 'Ham Sandwhich', '3.47', none}]

	products = sql db {
		select from Product where quantity !is none
	}!

	// println(products)
	assert products == [Product{1, 'Ice Cream', '5.99', 17}, Product{3, 'Bagel', '1.25', 45}]

	products = sql db {
		select from Product where price > '3' && price < '3.50'
	}!
	// println(products)

	assert products == [Product{2, 'Ham Sandwhich', '3.47', none}]

	products = sql db {
		select from Product where price < '2.000' || price >= '5'
	}!

	assert products == [Product{1, 'Ice Cream', '5.99', 17}, Product{3, 'Bagel', '1.25', 45}]
}
