source environment.sh
CRIU_IMAGE_DIR="/tmp/payaraMicroJEE8ExampleImage"
PAYARA_VERSION="5.2020.3";
PAYARA_MICRO_ROOT_DIR="/tmp/payaraMicroJEE8Example"
TMP_DIR="/var/tmp"
PAYARA_APP="$TMP_DIR/payara-micro-$PAYARA_VERSION.jar"

docker_build() {
  docker-compose build
}

docker_build_app() {
  docker-compose build app
}

docker_build_database() {
  docker-compose build database
}

docker_run_database() {
  docker-compose up database -d
  is_db_ready
  mvn flyway:migrate -f database/
}

docker_clean() {
  echo "DOCKER::CLEAN"
  docker kill jee8-example_app_1
  docker kill jee8-example_database_1
  docker rm -f jee8-example_app_1
  docker rm -f jee8-example_database_1
  docker rmi -f example/app
  docker rmi -f example/db
}

build_app() {
  mvn clean install -f app/
  echo "" > app/target/app/.reload
}

build_database() {
  mvn clean install -f database/
}

build_app_minimal() {
	mvn prepare-package war:exploded -Dmaven.test.skip -f app/
	echo "" > app/target/app/.reload
}


kill_app_server() {
  echo "PAYARA::KILL"
  PAYARA_MICRO_PROCESS_ID=`ps -au | grep java | grep payara-micro | awk '{print $2}'`
	if [[ ! -z "$PAYARA_MICRO_PROCESS_ID" ]]; then
		echo "Killing payara micro with pid '$PAYARA_MICRO_PROCESS_ID'";
		kill -SIGKILL $PAYARA_MICRO_PROCESS_ID;
	else
		echo "Can't find running payara micro process!"
	fi
}

run_app_server() {
  echo "PAYARA::RUN"
  java    -XX:-UsePerfData\
			    -XX:+TieredCompilation\
			    -XX:TieredStopAtLevel=1\
			    -XX:+UseParallelGC\
			    -Xverify:none\
			    -Xdebug\
			    -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address="$APP_DEBUG_PORT"\
			    -jar "$PAYARA_APP" \
			    --deploy app/target/app\
			    --nocluster \
			    --contextroot / \
			    --port "$APP_HTTP_PORT" \
			    --rootDir "$PAYARA_MICRO_ROOT_DIR" &
}

criu_dump() {
  echo "CRIU::DUMP"
	rm -rf "$CRIU_IMAGE_DIR"
	mkdir -p "$CRIU_IMAGE_DIR"
	PAYARA_MICRO_PROCESS_ID=`ps -au | grep java | grep payara-micro | awk '{print $2}'`
	sudo criu dump -vvvv -t $PAYARA_MICRO_PROCESS_ID --shell-job --log-file criu-dump.log --tcp-established --images-dir "$CRIU_IMAGE_DIR"
}

criu_restore() {
  echo "CRIU::RESTORE"
	sudo criu-ns restore -vvvv --shell-job --log-file criu-restore.log --tcp-established --images-dir "$CRIU_IMAGE_DIR" &
	is_app_ready
}

clean_up() {
  sudo rm -fr "$CRIU_IMAGE_DIR"
  sudo rm -fr "$PAYARA_MICRO_ROOT_DIR"
}

get_app_server() {
	echo "PAYARA::GET"
	# check for latests payara version (https://repo1.maven.org/maven2/fish/payara/extras/payara-micro/maven-metadata.xml metadata/versioning/latest or release?) and inform if differ from $PAYARA_VERSION
	if [ ! -f "$PAYARA_APP" ]
		then
			curl "https://repo1.maven.org/maven2/fish/payara/extras/payara-micro/$PAYARA_VERSION/payara-micro-$PAYARA_VERSION.jar" -o "$PAYARA_APP"
	fi
}

is_app_ready() {
  check_response_code status 200
}

check_response_code() {
  URL=http://$APP_HOST:$APP_HTTP_PORT/$1
  NEXT_WAIT_TIME=1
  MAX_WAIT_TIME=60
  SLEEP_TIME=0.25 # 250ms
  until [ $NEXT_WAIT_TIME -gt $MAX_WAIT_TIME ] || [ $(curl -s -o /dev/null -w "%{http_code}" $URL) == $2 ]; do
    echo "CHECK::APP - Waiting for application to be ready to handle http traffic. Check url is $URL. Check $NEXT_WAIT_TIME of $MAX_WAIT_TIME."
    sleep $SLEEP_TIME
    (( NEXT_WAIT_TIME++ ))
  done
  if [ $NEXT_WAIT_TIME -gt $MAX_WAIT_TIME ]
  then
    echo "CHECK::APP - Application is not ready to handle http traffic. Waited $MAX_WAIT_TIME x $SLEEP_TIME sec. Check url was $URL"
  else
    echo "CHECK::APP - Application is ready to handle http traffic. Check url was $URL"
  fi
}

is_db_ready() {
  # TODO:
  sleep 10
}

# If you include this function in a another shell script and try using with criu it will fail. This has something todo with the fact that the script opens a new session (needs verification)
# To be able to use criu use this function directly after source functions.sh
run_app() {
  kill_app_server
  if [ -d "$CRIU_IMAGE_DIR" ]
	then
		criu_restore
	else
		get_app_server
		run_app_server
		is_app_ready
		criu_dump
		criu_restore
  fi
}
