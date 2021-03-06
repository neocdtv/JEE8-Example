#!/bin/bash

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL

CREATE USER ${RESOURCE_USER} WITH CREATEDB PASSWORD '${RESOURCE_PASS}';
GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${RESOURCE_USER};

CREATE USER ${CONNECT_USER} with password '${CONNECT_PASS}';
GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${CONNECT_USER};
ALTER ROLE ${CONNECT_USER} NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT LOGIN;
EOSQL

psql -v ON_ERROR_STOP=1 -U "$RESOURCE_USER" -d "$POSTGRES_DB" <<-EOSQL

CREATE SCHEMA IF NOT EXISTS ${SCHEMA} AUTHORIZATION ${RESOURCE_USER};
GRANT USAGE ON SCHEMA ${SCHEMA} TO ${CONNECT_USER};
GRANT SELECT ON ALL TABLES IN SCHEMA ${SCHEMA} TO ${CONNECT_USER};
GRANT SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA ${SCHEMA}  TO ${CONNECT_USER};
ALTER ROLE ${RESOURCE_USER} set search_path = ${SCHEMA};
EOSQL

psql -v ON_ERROR_STOP=1 -U "$CONNECT_USER" -d "$POSTGRES_DB" <<-EOSQL

ALTER ROLE ${CONNECT_USER} set search_path = ${SCHEMA};
EOSQL
