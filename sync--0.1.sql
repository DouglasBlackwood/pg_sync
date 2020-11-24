\echo Use "CREATE EXTENSION sync;" to load this file. \quit

COMMENT ON EXTENSION sync
	IS 'Extension PostgreSQL pour pouvoir synchroniser des tables entre plusieurs bases de données';

CREATE TABLE IF NOT EXISTS sync.db_id
(
	db_id text
);
