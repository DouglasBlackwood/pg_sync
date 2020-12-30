\echo Use "CREATE EXTENSION sync;" to load this file. \quit

COMMENT ON EXTENSION sync
	IS 'Extension PostgreSQL pour pouvoir synchroniser des tables entre plusieurs bases de données';



CREATE TABLE IF NOT EXISTS sync.db_id
(
	db_id uuid NOT NULL PRIMARY KEY,
	is_main boolean NOT NULL DEFAULT FALSE
);

INSERT INTO sync.db_id(db_id) VALUES (public.uuid_generate_v4());

CREATE OR REPLACE FUNCTION sync.db_id_locker() RETURNS trigger LANGUAGE plpgsql AS
	$BODY$
	BEGIN
		RAISE EXCEPTION 'sync.db_id is locked!';
	END;
	$BODY$;

CREATE TRIGGER db_id_lock
	BEFORE INSERT OR DELETE
	ON sync.db_id
	FOR EACH ROW
	EXECUTE PROCEDURE sync.db_id_locker();



CREATE OR REPLACE FUNCTION sync.set_database_as_main() RETURNS void LANGUAGE sql AS
	$$ UPDATE sync.db_id SET is_main = TRUE; $$;
COMMENT ON FUNCTION sync.set_database_as_main() IS 'Set the database as the main database';



CREATE OR REPLACE FUNCTION sync.db_id() RETURNS uuid LANGUAGE sql STABLE AS
	$$ SELECT db_id FROM sync.db_id; $$;
COMMENT ON FUNCTION sync.db_id() IS 'Returns database ID';

CREATE OR REPLACE FUNCTION sync.is_main() RETURNS boolean LANGUAGE sql STABLE AS
	$$ SELECT is_main FROM sync.db_id; $$;
COMMENT ON FUNCTION sync.is_main() IS 'Returns whether this database is the main database';

CREATE OR REPLACE FUNCTION sync.is_server() RETURNS boolean LANGUAGE sql STABLE AS
	$$ SELECT is_main FROM sync.db_id; $$;
COMMENT ON FUNCTION sync.is_server() IS 'Returns whether this database is the main database';

CREATE OR REPLACE FUNCTION sync.is_replica() RETURNS boolean LANGUAGE sql STABLE AS
	$$ SELECT NOT is_main FROM sync.db_id; $$;
COMMENT ON FUNCTION sync.is_replica() IS 'Returns whether this database is a replica';



CREATE OR REPLACE FUNCTION sync.install_tracer(_table regclass)
	RETURNS void
	LANGUAGE plpgsql
AS
$BODY$
BEGIN
	SET client_min_messages TO WARNING;

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
		IF OLD.pgs_is_active IS NULL THEN
			RETURN OLD;
		ELSE
			RETURN NULL;
		END IF;

	ELSE
		NEW.pgs_changed_at = statement_timestamp();

		IF sync.is_main() THEN
			NEW.pgs_synced_at = statement_timestamp();
		ELSE
			NEW.pgs_synced_at = NULL;
		END IF;

		RETURN NEW;

	END IF;
END;
$BODY$;
