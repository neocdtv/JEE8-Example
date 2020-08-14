source environment.sh
CRIU_IMAGE_DIR="/tmp/payaraMicroJEE8ExampleImage"
PAYARA_MICRO_ROOT_DIR="/tmp/payaraMicroJEE8Example"

build_app() {
  mvn clean install -f app/
  echo "" > app/target/app/.reload
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
			    -jar /var/tmp/payara-micro.jar \
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
	sudo criu-ns restore -vvvv --shell-job --log-file criu-restore.log --tcp-established --images-dir "$CRIU_IMAGE_DIR"
}

clean_up() {
  sudo rm -fr "$CRIU_IMAGE_DIR"
  sudo rm -fr "$PAYARA_MICRO_ROOT_DIR"
}

is_app_running() {
  # TODO: pool, curl on status url
  sleep 18
}

# If you include this function in a another shell script and try using with criu it will fail. This has something todo with the fact that the script opens a new session (needs verification)
# To be able to use criu use this function directly after source ./functions.sh
run_app() {
  kill_app_server
  if [ -d "$CRIU_IMAGE_DIR" ]
	then
		criu_restore
	else
    run_app_server
		is_app_running
		criu_dump
		criu_restore
  fi
}
