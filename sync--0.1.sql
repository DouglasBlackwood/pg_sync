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



CREATE TABLE IF NOT EXISTS sync.metadata
(
	table_id regclass primary key,
	synced_at TIMESTAMP WITH TIME ZONE,
	download boolean not null default true,
	upload boolean not null default true
);

SELECT pg_catalog.pg_extension_config_dump('sync.metadata', '');



CREATE OR REPLACE FUNCTION sync.install_tracer(_table regclass)
	RETURNS void
	LANGUAGE plpgsql
AS
$BODY$
DECLARE
	_primary_keys TEXT = (
		SELECT string_agg(quote_literal(attname), ',')
		FROM pg_index
			JOIN pg_attribute ON  attrelid = indrelid AND attnum = ANY(indkey)
		WHERE indrelid = _table AND indisprimary
	);
	_index_name TEXT = (select relname from pg_class where oid = _table) || '_pgs_synced_at_idx';
BEGIN
	IF _primary_keys IS NULL THEN
		RAISE WARNING 'no primary key detected, delete operations will not be available';
	END IF;

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
			EXECUTE PROCEDURE sync.trace_changes(%s)
		$$,
		_table,
		_primary_keys
	);

	EXECUTE FORMAT('DROP INDEX IF EXISTS %I;', _index_name);
	EXECUTE FORMAT(
		'CREATE INDEX %I ON %I (pgs_synced_at DESC NULLS FIRST)',
		_index_name,
		_table
	);

	EXECUTE FORMAT(
		$$
			INSERT INTO sync.metadata(table_id, synced_at, download, upload)
			SELECT %L, max(pgs_synced_at), TRUE, TRUE
			FROM %I
			ON CONFLICT (table_id) DO UPDATE SET synced_at = EXCLUDED.synced_at;
		$$,
		_table,
		_table
	);
END;
$BODY$;



CREATE OR REPLACE FUNCTION sync.trace_changes()
	RETURNS trigger
	LANGUAGE plpgsql
AS
$BODY$
DECLARE _sql_delete text;
BEGIN
	IF TG_OP = 'DELETE' THEN
		IF OLD.pgs_is_active IS NULL THEN
			RETURN OLD;

		ELSE
			IF TG_NARGS = 0 THEN
				RAISE EXCEPTION 'primary key is missing as trigger args';
			END IF;

			IF OLD.pgs_is_active THEN
				_sql_delete := FORMAT(
					'UPDATE %I.%I SET pgs_is_active = FALSE WHERE (%s) = (%s)',
					TG_TABLE_SCHEMA,
					TG_TABLE_NAME,
					array_to_string(array(SELECT quote_ident(c) FROM UNNEST(TG_ARGV) t(c)), ','),
					array_to_string(array(SELECT '$1.' || quote_ident(c) FROM UNNEST(TG_ARGV) t(c)), ',')
				);

				EXECUTE _sql_delete USING OLD;
			END IF;

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
