\echo Use "CREATE EXTENSION sync;" to load this file. \quit

COMMENT ON EXTENSION sync
	IS 'Extension PostgreSQL pour pouvoir synchroniser des tables entre plusieurs bases de données';

CREATE TABLE IF NOT EXISTS sync.db_id
(
	db_id uuid NOT NULL PRIMARY KEY,
	main boolean NOT NULL DEFAULT FALSE
);

INSERT INTO sync.db_id VALUES (public.uuid_generate_v4());

CREATE OR REPLACE FUNCTION sync.db_id()
	RETURNS uuid
	LANGUAGE sql
AS
$$
	SELECT db_id FROM sync.db_id;
$$;

CREATE OR REPLACE FUNCTION sync.is_main()
	RETURNS boolean
	LANGUAGE sql
AS
$$
	SELECT main FROM sync.db_id;
$$;

CREATE OR REPLACE FUNCTION sync.is_server()
	RETURNS boolean
	LANGUAGE sql
AS
$$
	SELECT main FROM sync.db_id;
$$;
