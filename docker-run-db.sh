#!/bin/bash
docker run -p 5432:5432 --env-file ./.env example-db
