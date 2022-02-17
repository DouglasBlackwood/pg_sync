BEGIN;
SELECT plan(2);

SET client_min_messages TO WARNING;

SELECT faker.faker('fr_FR');

-- Définit la base de données comme la base principale
SELECT sync.set_database_as_main();

CREATE TEMP TABLE people
(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	first_name TEXT,
	last_name TEXT
);

-- Installe les colonnes et trigger
SELECT sync.install_tracer('people');

INSERT INTO people (first_name, last_name)
VALUES
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name());

-- Tests UPDATE
UPDATE people SET pgs_changed_at = 'tomorrow', pgs_synced_at = 'tomorrow';
SELECT ok(pgs_changed_at <= statement_timestamp(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT ok(pgs_synced_at <= statement_timestamp(), 'wrong pgs_synced_at') FROM people LIMIT 1;

SELECT * FROM finish();
ROLLBACK;
