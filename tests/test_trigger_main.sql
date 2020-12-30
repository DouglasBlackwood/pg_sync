BEGIN;
SELECT plan(2);

-- Définit la base de données comme la base principale
SELECT sync.set_database_as_main();

CREATE TEMP TABLE people
(
	id INT GENERATED ALWAYS AS IDENTITY,
	first_name TEXT,
	last_name TEXT
);

-- Installe les colonnes et trigger
SELECT sync.install_tracer('people');

INSERT INTO people (first_name, last_name)
VALUES
	('Mike', 'Tyson'),
	('Michel', 'Zecler'),
	('Diego', 'Maradona'),
	('Hassan', 'Rohani'),
	('Alex', 'Thomson');

-- Tests UPDATE
UPDATE people SET pgs_changed_at = 'tomorrow', pgs_synced_at = 'tomorrow';
SELECT ok(pgs_changed_at <= statement_timestamp(), 'wrong pgs_changed_at') FROM people LIMIT 1;
SELECT ok(pgs_synced_at <= statement_timestamp(), 'wrong pgs_synced_at') FROM people LIMIT 1;

SELECT * FROM finish();
ROLLBACK;
