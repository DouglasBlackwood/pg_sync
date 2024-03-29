BEGIN;
SELECT plan(5);

SET client_min_messages TO WARNING;

SELECT faker.faker('fr_FR');

CREATE TEMP TABLE people
(
	id1 INT,
	id2 INT,
	first_name TEXT,
	last_name TEXT,
	PRIMARY KEY (id1, id2)
);

-- Installe les colonnes et trigger
SELECT sync.install_tracer('people');

-- Vérifie que la fonction peut être appelée deux fois
SELECT sync.install_tracer('people');

-- Tests INSERT
INSERT INTO people (id1, id2, first_name, last_name)
VALUES
	(1, 1, faker.first_name(), faker.last_name()),
	(1, 2, faker.first_name(), faker.last_name()),
	(1, 3, faker.first_name(), faker.last_name()),
	(1, 4, faker.first_name(), faker.last_name()),
	(1, 5, faker.first_name(), faker.last_name());

-- Tests DELETE
DELETE FROM people;
SELECT ok(COUNT(*) = 5) FROM people;
SELECT ok(NOT pgs_is_active) FROM people LIMIT 1;
SELECT ok(pgs_changed_at >= now(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT ok(pgs_changed_at <= statement_timestamp(), 'wrong pgs_changed_at') FROM people LIMIT 1;

UPDATE people SET pgs_is_active = NULL;
DELETE FROM people;
SELECT ok(COUNT(*) = 0) FROM people;

SELECT * FROM finish();
ROLLBACK;
