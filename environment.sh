#!/bin/bash
source <(grep -v '^ *#' $JEE8_EXAMPLE_HOME/.env | grep '[^ ] *=' | awk '{split($0,a,"="); print gensub(/\./, "_", "g", "export " a[1]) "=" a[2]}')
export APP_HOST=localhost
export DB_HOST=localhost
export DB_NAME=${POSTGRES_DB}
export DB_USER=${CONNECT_USER}
export DB_PASS=${CONNECT_PASS}

