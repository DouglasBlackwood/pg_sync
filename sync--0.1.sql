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
	STABLE
AS
$$
	SELECT db_id FROM sync.db_id;
$$;

COMMENT ON FUNCTION sync.db_id() IS 'Returns database ID';

CREATE OR REPLACE FUNCTION sync.is_main()
	RETURNS boolean
	LANGUAGE sql
	STABLE
AS
$$
	SELECT main FROM sync.db_id;
$$;

COMMENT ON FUNCTION sync.is_main() IS 'Returns whether this database is the main database';

CREATE OR REPLACE FUNCTION sync.is_server()
	RETURNS boolean
	LANGUAGE sql
	STABLE
AS
$$
	SELECT main FROM sync.db_id;
$$;

COMMENT ON FUNCTION sync.is_server() IS 'Returns whether this database is the main database';

CREATE OR REPLACE FUNCTION sync.is_replica()
	RETURNS boolean
	LANGUAGE sql
	STABLE
AS
$$
	SELECT NOT main FROM sync.db_id;
$$;

COMMENT ON FUNCTION sync.is_replica() IS 'Returns whether this database is a replica';

CREATE OR REPLACE FUNCTION sync.install_tracer(_table regclass)
	RETURNS void
	LANGUAGE plpgsql
AS
$BODY$
BEGIN
	BEGIN
		EXECUTE FORMAT('ALTER TABLE %I ADD COLUMN pgs_is_active BOOLEAN DEFAULT TRUE;', _table);
	EXCEPTION WHEN duplicate_column THEN
		RAISE NOTICE 'pgs_is_active already exists';
	END;

	BEGIN
		EXECUTE FORMAT('ALTER TABLE %I ADD COLUMN pgs_changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT statement_timestamp();', _table);
	EXCEPTION WHEN duplicate_column THEN
		RAISE NOTICE 'pgs_changed_at already exists';
	END;

	BEGIN
		EXECUTE FORMAT('ALTER TABLE %I ADD COLUMN pgs_synced_at TIMESTAMP WITH TIME ZONE DEFAULT statement_timestamp();', _table);
	EXCEPTION WHEN duplicate_column THEN
		RAISE NOTICE 'pgs_synced_at already exists';
	END;

	EXECUTE FORMAT('DROP TRIGGER IF EXISTS pgs_trace_changes ON %I;', _table);
	EXECUTE FORMAT(
		$$
			CREATE TRIGGER pgs_trace_changes
			BEFORE INSERT OR UPDATE OR DELETE
			ON %I
			FOR EACH ROW
			EXECUTE PROCEDURE sync.trace_changes()
		$$,
		_table
	);
END;
$BODY$;

CREATE OR REPLACE FUNCTION sync.trace_changes()
	RETURNS trigger
	LANGUAGE plpgsql
AS
$BODY$
BEGIN
	IF TG_OP = 'DELETE' THEN
		RETURN NULL;
	ELSE
		NEW.pgs_changed_at = statement_timestamp();
		NEW.pgs_synced_at = NULL;
		RETURN NEW;
	END IF;
END;
$BODY$;
