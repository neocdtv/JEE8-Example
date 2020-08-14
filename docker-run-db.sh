#!/bin/bash
source ./setup_vars.sh
docker run -p 5432:5432 --env-file ./.env example/db
