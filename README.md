# pg_sync

Extension PostgreSQL pour pouvoir synchroniser des tables entre plusieurs bases de données.

## Exécuter les tests avec Docker

    docker-compose up --build tests && docker-compose down

## TODO

- si la pkey change, le trigger devient invalide
- erreur si un utilisateur autre que le super admin veut utiliser les fonctions du schéma sync
