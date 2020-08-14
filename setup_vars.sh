#!/bin/bash
source <(grep -v '^ *#' ./.env | grep '[^ ] *=' | awk '{split($0,a,"="); print gensub(/\./, "_", "g", "export " a[1]) "=" a[2]}')
# app
export DB_NAME=$POSTGRES_DB
export DB_PASS=$CONNECT_PASS
export DB_HOST=localhost
