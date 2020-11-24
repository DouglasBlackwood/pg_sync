-- Start transaction and plan the tests.
BEGIN;
SELECT plan(1);

-- Run the tests.
SELECT has_table('sync', 'db_id', 'table db_id is missing');

-- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK;
