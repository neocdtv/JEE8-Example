#!/bin/bash
source <(grep -v '^ *#' $JEE8_EXAMPLE_HOME/.env | grep '[^ ] *=' | awk '{split($0,a,"="); print gensub(/\./, "_", "g", "export " a[1]) "=" a[2]}')
# app, same settings as in docker-compose.yml, but required to run the app w/o docker-compose
export APP_HOST=localhost
export DB_HOST=localhost
export DB_PORT=${DB_PORT}
export DB_NAME=${POSTGRES_DB}
export DB_USER=${CONNECT_USER}
export DB_PASS=${CONNECT_PASS}

