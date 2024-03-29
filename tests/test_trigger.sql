BEGIN;
SELECT plan(19);

SET client_min_messages TO WARNING;

SELECT faker.faker('fr_FR');

CREATE TEMP TABLE people
(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	first_name TEXT,
	last_name TEXT
);

-- Installe les colonnes et trigger
SELECT sync.install_tracer('people');

SELECT has_column('people', 'pgs_is_active', 'column pgs_is_active is missing');
SELECT has_column('people', 'pgs_changed_at', 'column pgs_changed_at is missing');
SELECT col_not_null('people', 'pgs_changed_at', 'column pgs_changed_at must have NOT NULL constraint');
SELECT has_column('people', 'pgs_synced_at', 'column pgs_synced_at is missing');
SELECT col_is_null('people', 'pgs_synced_at', 'column pgs_synced_at must have NOT NULL constraint');
SELECT has_trigger('people', 'pgs_trace_changes', 'trigger pgs_trace_changes is missing');
SELECT has_index('people', 'people_pgs_synced_at_idx', ARRAY['pgs_synced_at'], 'index people_pgs_synced_at_idx is missing');

-- Vérifie que la fonction peut être appelée deux fois
SELECT sync.install_tracer('people');

-- Tests INSERT
INSERT INTO people (first_name, last_name)
VALUES
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name()),
	(faker.first_name(), faker.last_name());

SELECT is(pgs_is_active, TRUE, 'pgs_is_active must be TRUE') FROM people LIMIT 1;
SELECT ok(pgs_changed_at >= now(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT ok(pgs_changed_at <= statement_timestamp(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT is(pgs_synced_at, NULL, 'pgs_synced_at must be null') FROM people LIMIT 1;

-- Tests UPDATE
UPDATE people SET pgs_changed_at = 'tomorrow', pgs_synced_at = 'tomorrow';
SELECT ok(pgs_changed_at <= statement_timestamp(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT is(pgs_synced_at, NULL, 'pgs_synced_at must be null') FROM people LIMIT 1;

-- Tests DELETE
DELETE FROM people;
SELECT ok(COUNT(*) = 5) FROM people;
SELECT ok(NOT pgs_is_active) FROM people LIMIT 1;
SELECT ok(pgs_changed_at >= now(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT ok(pgs_changed_at <= statement_timestamp(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT ok(pgs_synced_at IS NULL, 'pgs_synced_at must be null') FROM people LIMIT 1;

UPDATE people SET pgs_is_active = NULL;
DELETE FROM people;
SELECT ok(COUNT(*) = 0) FROM people;

SELECT * FROM finish();
ROLLBACK;
