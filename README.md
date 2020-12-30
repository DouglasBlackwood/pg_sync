# pg_sync

Extension PostgreSQL pour pouvoir synchroniser des tables entre plusieurs bases de données.


## Exécuter les tests avec Docker

	docker-compose up --build tests && docker-compose down


## TODO

- créer stg_synchro (metadata)
- compléter stg_synchro lors du create extension
- index sur pg_synced_at ?
- mode modification ? ne pas créer pg_modified_at
- test delete multi primary key
