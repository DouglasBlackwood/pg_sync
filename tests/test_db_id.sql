BEGIN;
SELECT plan(19);

SELECT has_table('sync', 'db_id', 'table db_id is missing');

SELECT has_column('sync', 'db_id', 'db_id', 'column db_id.db_id is missing');
SELECT col_not_null('sync', 'db_id', 'db_id', 'column db_id.db_id must have NOT NULL constraint');
SELECT col_type_is('sync', 'db_id', 'db_id', 'uuid', 'column db_id.db_id must be UUID');
SELECT col_is_pk('sync', 'db_id', 'db_id', 'column db_id.db_id must be PRIMARY KEY');

SELECT ok(count(*) = 1, 'db_id is missing') FROM sync.db_id;

SELECT has_function('sync', 'db_id', 'function db_id() is missing');
SELECT ok(db_id = sync.db_id()) FROM sync.db_id;

SELECT has_column('sync', 'db_id', 'main', 'column db_id.main is missing');
SELECT col_not_null('sync', 'db_id', 'main', 'column db_id.main must have NOT NULL constraint');
SELECT col_type_is('sync', 'db_id', 'main', 'boolean', 'column db_id.main must be BOOLEAN');
SELECT col_has_default('sync', 'db_id', 'main', 'column db_id.main must have DEFAULT value');
SELECT col_default_is('sync', 'db_id', 'main', FALSE, 'column db_id.main must have DEFAULT value to FALSE');

SELECT has_function('sync', 'is_main', 'function is_main() is missing');
SELECT ok(sync.is_main() = FALSE);
SELECT has_function('sync', 'is_server', 'function is_server() is missing');
SELECT ok(sync.is_server() = sync.is_main());
SELECT has_function('sync', 'is_replica', 'function is_replica() is missing');
SELECT ok(sync.is_replica() = TRUE);

SELECT * FROM finish();
ROLLBACK;