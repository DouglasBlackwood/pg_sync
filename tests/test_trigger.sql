BEGIN;
SELECT plan(13);

CREATE TEMP TABLE people
(
	id INT GENERATED ALWAYS AS IDENTITY,
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

-- Vérifie que la fonction peut être appelée deux fois
SELECT sync.install_tracer('people');

-- Tests INSERT
INSERT INTO people (first_name, last_name)
VALUES
	('Mike', 'Tyson'),
	('Michel', 'Zecler'),
	('Diego', 'Maradona'),
	('Hassan', 'Rohani'),
	('Alex', 'Thomson');

SELECT ok(pgs_is_active, 'pgs_is_active must be TRUE') FROM people LIMIT 1;
SELECT ok(pgs_changed_at >= now(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT ok(pgs_changed_at <= statement_timestamp(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT ok(pgs_synced_at IS NULL, 'pgs_synced_at must be null') FROM people LIMIT 1;

-- Tests DELETE
DELETE FROM people;
SELECT ok(COUNT(*) = 5) FROM people;

-- Tests UPDATE
UPDATE people SET pgs_changed_at = 'tomorrow', pgs_synced_at = 'tomorrow';
SELECT ok(pgs_changed_at <= statement_timestamp(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT ok(pgs_synced_at IS NULL, 'pgs_synced_at must be null') FROM people LIMIT 1;

SELECT * FROM finish();
ROLLBACK;
