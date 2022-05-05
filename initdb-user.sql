CREATE USER test_user NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD 'pass';

CREATE SCHEMA hide_schema;
GRANT ALL ON SCHEMA hide_schema TO test_user;

GRANT EXECUTE ON FUNCTION sync.set_database_as_main() TO test_user;
GRANT UPDATE ON TABLE sync.db_id TO test_user;
GRANT TRUNCATE ON TABLE sync.metadata TO test_user;
