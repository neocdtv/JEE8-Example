#!/bin/bash
until docker exec -it ccr_db_1 pg_isready --host=localhost --port=5432 --username=res_user --dbname=example #&>/dev/null
  do
  	echo "Waiting for postgresql connection with user res_user and db ccr to be available..."
		sleep 1
	done