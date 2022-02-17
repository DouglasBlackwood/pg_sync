BEGIN;
SELECT plan(5);

SET client_min_messages TO WARNING;

SELECT faker.faker('fr_FR');

TRUNCATE sync.metadata;
SELECT sync.set_database_as_main();

CREATE TEMP TABLE people
(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	first_name TEXT,
	last_name TEXT
);

SELECT sync.install_tracer('people');

SELECT ok(COUNT(*) = 1) FROM sync.metadata;
SELECT is(synced_at, NULL, 'synced_at is not null') FROM sync.metadata WHERE table_id = 'people'::regclass;

INSERT INTO people (first_name, last_name)
VALUES
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name());

SELECT ok(COUNT(*) = 5, 'test table is empty') FROM people;
SELECT isnt(max(pgs_synced_at), NULL, 'pgs_synced_at is empty') FROM people;

SELECT sync.update_metadata();

SELECT results_eq(
		$$SELECT synced_at FROM sync.metadata WHERE table_id = 'people'::regclass$$,
		$$SELECT max(pgs_synced_at) FROM people$$
	);

SELECT * FROM finish();
ROLLBACK;
