BEGIN;
SELECT plan(12);

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


SELECT ok(COUNT(*) = 0) FROM sync.metadata;

SET client_min_messages TO WARNING;

CREATE TEMP TABLE people
(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	first_name TEXT,
	last_name TEXT
);

SELECT sync.install_tracer('people');

SELECT ok(COUNT(*) = 1) FROM sync.metadata;

SELECT * FROM finish();
ROLLBACK;
