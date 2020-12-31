BEGIN;
SELECT plan(11);

SELECT has_table('sync', 'metadata', 'table metadata is missing');

SELECT has_column('sync', 'metadata', 'table_id', 'column metadata.table_id is missing');
SELECT col_not_null('sync', 'metadata', 'table_id', 'column metadata.table_id must have NOT NULL constraint');
SELECT col_type_is('sync', 'metadata', 'table_id', 'regclass', 'column metadata.table_id must be regclass');
SELECT col_is_pk('sync', 'metadata', 'table_id', 'column metadata.table_id must be PRIMARY KEY');

SELECT has_column('sync', 'metadata', 'synced_at', 'column metadata.synced_at is missing');

SELECT has_column('sync', 'metadata', 'download', 'column metadata.download is missing');
SELECT col_not_null('sync', 'metadata', 'download', 'column metadata.download must have NOT NULL constraint');

SELECT has_column('sync', 'metadata', 'upload', 'column metadata.upload is missing');
SELECT col_not_null('sync', 'metadata', 'upload', 'column metadata.upload must have NOT NULL constraint');

SELECT has_column('sync', 'metadata', 'ordinality', 'column metadata.ordinality is missing');

SELECT * FROM finish();
ROLLBACK;
