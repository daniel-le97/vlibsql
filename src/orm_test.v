module vlibsql

import orm
import time

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

	println(all)

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
