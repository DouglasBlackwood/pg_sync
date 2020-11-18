# pg_sync

Extension PostgreSQL pour pouvoir synchroniser des tables entre plusieurs bases de données.


## Docker

	docker build -t pg_sync_test .
	docker run --name db --rm -d pg_sync_test
	docker logs -f db

	docker run -it --rm --link db:postgres -e PGPASSWORD=postgres postgres psql -h db -U postgres

	docker run --rm --link db:postgres -e PGPASSWORD=postgres -v ~/dev/pg_sync/tests/:/tests pg_sync_test pg_prove -h db -U postgres --ext=".sql" /tests

	docker stop db
