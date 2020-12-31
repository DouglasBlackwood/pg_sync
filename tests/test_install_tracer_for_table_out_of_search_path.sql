BEGIN;
SELECT plan(1);

SET client_min_messages TO WARNING;
SET search_path TO public;

DROP SCHEMA IF EXISTS hide_schema;

CREATE SCHEMA hide_schema;

CREATE TABLE hide_schema.hide_table
(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name TEXT
);

SELECT sync.install_tracer('hide_schema.hide_table');

SELECT ok(COUNT(*) = 1) FROM sync.metadata WHERE table_id = 'hide_schema.hide_table'::regclass;

SELECT * FROM finish();
ROLLBACK;
