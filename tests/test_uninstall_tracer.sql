BEGIN;
SELECT plan(7);

SET client_min_messages TO WARNING;

CREATE TEMP TABLE people
(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	first_name TEXT,
	last_name TEXT
);

SELECT sync.install_tracer('people', _download:=FALSE, _upload:=FALSE);

SELECT ok(COUNT(*) = 1) FROM sync.metadata;

SELECT sync.uninstall_tracer('people');

SELECT ok(COUNT(*) = 0, 'sync.metadata should be empty') FROM sync.metadata;

SELECT hasnt_column('people', 'pgs_is_active', 'column pgs_is_active should be dropped');
SELECT hasnt_column('people', 'pgs_changed_at', 'column pgs_changed_at should be dropped');
SELECT hasnt_column('people', 'pgs_synced_at', 'column pgs_synced_at should be dropped');
SELECT hasnt_trigger('people', 'pgs_trace_changes', 'trigger pgs_trace_changes should be dropped');
SELECT hasnt_index('people', 'people_pgs_synced_at_idx', 'index people_pgs_synced_at_idx should be dropped');

SELECT * FROM finish();
ROLLBACK;
