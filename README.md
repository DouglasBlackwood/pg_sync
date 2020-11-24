# pg_sync

Extension PostgreSQL pour pouvoir synchroniser des tables entre plusieurs bases de données.


## Exécuter les tests avec Docker

	docker-compose up --build tests && docker-compose down


## TODO

- créer db_id
- bloquer insert/delete sur db_id
- créer stg_synchro (metadata)
- créer fct trigger
- créer colonnes sync
