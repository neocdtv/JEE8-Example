#!/bin/bash
source $JEE8_EXAMPLE_HOME/environment.sh
TMP_DIR="/var/tmp"
CRIU_IMAGE_DIR="$TMP_DIR/payaraMicroJEE8ExampleImage"
PAYARA_MICRO_ROOT_DIR="$TMP_DIR/payaraMicroJEE8Example"
PAYARA_VERSION="5.2020.3";
PAYARA_APP="$TMP_DIR/payara-micro-$PAYARA_VERSION.jar"
DOCKER_DATABASE_CONTAINER_NAME="jee8-example_database_1"
DOCKER_APP_CONTAINER_NAME="jee8-example_app_1"

PAYARA_WARMED_UP_CLASSES_LST="payara-classes.lst"
PAYARA_WARMED_UP_CLASSES_JSA="payara-classes.jsa"
PAYARA_WARMED_UP_LAUNCHER="launch-micro.jar"

do_all() {
  database_build $1
  database_run
  app_build $1
  app_run  
}

database_build() {
  database_clean $1
  print_info "DATABASE::BUILD"
  docker-compose -f $JEE8_EXAMPLE_HOME/docker-compose.yml build database
}

database_run() {
  print_info "DATABASE::RUN"
  docker-compose -f $JEE8_EXAMPLE_HOME/docker-compose.yml up -d database
  is_database_ready
  if [ $? -ne 0 ]
  then
    return 1;
  fi
  mvn prepare-package flyway:migrate -f $JEE8_EXAMPLE_HOME/database/
}

database_clean() {
  print_info "DATABASE::CLEAN"
  docker ps | grep "$DOCKER_DATABASE_CONTAINER_NAME" &>/dev/null
  if [ $? == 0 ]
  then 
    mvn flyway:clean -f $JEE8_EXAMPLE_HOME/database/
    docker kill $DOCKER_DATABASE_CONTAINER_NAME
  fi
  if [ "$1" == "hard" ] 
  then 
    docker rm -f $DOCKER_DATABASE_CONTAINER_NAME
    docker rmi -f example/db
  fi
  mvn clean -f $JEE8_EXAMPLE_HOME/database/
}

app_clean() {
  print_info "APP::CLEAN"
  if [ "$1" == "hard" ]
  then
    docker kill $DOCKER_APP_CONTAINER_NAME
    docker rm -f $DOCKER_APP_CONTAINER_NAME
    docker rmi -f example/app
    payara_kill
    #sudo rm -fvr "$CRIU_IMAGE_DIR"
    sudo rm -fvr "$PAYARA_MICRO_ROOT_DIR"
  fi
  mvn -T4 clean -f $JEE8_EXAMPLE_HOME/app/
}

app_build() {
  print_info "APP::BUILD"
  app_clean $1
  mvn -T4 prepare-package war:exploded -Dmaven.test.skip -f $JEE8_EXAMPLE_HOME/app/
  if [ $? -eq 0 ]
  then
    echo `date +%s` > $JEE8_EXAMPLE_HOME/app/target/app/timestamp
    app_redeploy
  else
    return $?
  fi
}

app_rebuild() {
  print_info "APP::REBUILD"
  mvn -T4 prepare-package war:exploded -Dmaven.test.skip -o -f $JEE8_EXAMPLE_HOME/app/
  if [ $? -eq 0 ]
  then
    echo `date +%s` > $JEE8_EXAMPLE_HOME/app/target/app/timestamp
    app_redeploy
  else
    return $?
  fi
}

app_redeploy() {
  print_info "APP::REDEPLOY"
  # get status timestamp
  echo "" > $JEE8_EXAMPLE_HOME/app/target/app/.reload
  # wait for status timestamp to change
  # do it like in app_run
  # remove current criu dump
  # create criu dump
  # restore
}

payara_download() {
  local prefix="PAYARA::DOWNLOAD"
  print_info $prefix
  # check for latests payara version (https://repo1.maven.org/maven2/fish/payara/extras/payara-micro/maven-metadata.xml metadata/versioning/latest or release?) and inform if differ from $PAYARA_VERSION
  if [ ! -f "$PAYARA_APP" ]
  then
    print_info "$prefix - Payara $PAYARA_VERSION not available. Starting download..."
    curl "https://repo1.maven.org/maven2/fish/payara/extras/payara-micro/$PAYARA_VERSION/payara-micro-$PAYARA_VERSION.jar" -o "$PAYARA_APP"
  else 
    print_info "$prefix - Payara $PAYARA_VERSION available. No download needed."
  fi
}

payara_kill() {
  local prefix="PAYARA::KILL"
  local payara_pid="$(payara_find)"
	if [[ ! -z "$payara_pid" ]]; then
		print_info "$prefix - Killing payara micro with pid '$payara_pid'";
		kill -SIGKILL $payara_pid;
	else
		print_warn "$prefix - Can't find running payara micro process!"
	fi
}

payara_find() {
  local pid=`ps -aux | grep java | grep "launch-micro" | awk '{print $2}'`
  echo "$pid"
}

payara_run() {
  print_info "PAYARA::RUN"
  payara_download
  payara_warm_up
  java    -XX:-UsePerfData\
			    -XX:+TieredCompilation\
			    -XX:TieredStopAtLevel=1\
			    -XX:+UseParallelGC\
			    -Xverify:none\
			    -Xdebug\
			    -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address="$APP_DEBUG_PORT"\
			    -jar "$PAYARA_MICRO_ROOT_DIR/$PAYARA_WARMED_UP_LAUNCHER" \
			    --deploy "$JEE8_EXAMPLE_HOME/app/target/app"\
			    --nocluster \
			    --contextroot / \
			    --port "$APP_HTTP_PORT" &
}

is_payara_warmed_up() {
  local payara_root=$1
  if [ -f "$PAYARA_MICRO_ROOT_DIR/$PAYARA_WARMED_UP_LAUNCHER" ] && [ -f "$PAYARA_MICRO_ROOT_DIR/$PAYARA_WARMED_UP_CLASSES_JSA" ]; then
    return 0
  else
    return 1
  fi
}

payara_warm_up() {
    local prefix="PAYARA::WARM UP"
    local payara_root="$PAYARA_MICRO_ROOT_DIR"
    is_payara_warmed_up
    local payara_warmed_up=$?
    if [ ! $payara_warmed_up -eq 0 ]; then
      print_info "$prefix -  Payara at $payara_root is not warmed up (AppCDS). Warming up...";
      java\
        -jar "$PAYARA_APP" \
	      --nocluster\
	      --rootDir "$payara_root"\
	      --outputlauncher
      java\
        -XX:DumpLoadedClassList="$payara_root/$PAYARA_WARMED_UP_CLASSES_LST"\
        -jar "$payara_root/$PAYARA_WARMED_UP_LAUNCHER"\
        --nocluster\
        --warmup
      java\
        -Xshare:dump\
        -XX:SharedClassListFile="$payara_root/$PAYARA_WARMED_UP_CLASSES_LST"\
        -XX:SharedArchiveFile="$payara_root/$PAYARA_WARMED_UP_CLASSES_JSA"\
        -jar "$payara_root/$PAYARA_WARMED_UP_LAUNCHER"\
        --nocluster
    else
      print_info "$prefix - Payara at $payara_root is warmed up (AppCDS).";
    fi
}

app_dump() {
  print_info "APP::DUMP"
  rm -rf "$CRIU_IMAGE_DIR"
  mkdir -p "$CRIU_IMAGE_DIR"
  criu_dump
}

app_restore() {
  print_info "APP::RESTORE"
  criu_restore
  is_app_ready
}

criu_dump() {
  print_info "CRIU::DUMP"
  local payara_pid="$(payara_find)"
  sudo criu dump -vvvv --shell-job -t $payara_pid --log-file criu-dump.log --tcp-established --images-dir "$CRIU_IMAGE_DIR"
}

criu_restore() {
  print_info "CRIU::RESTORE"
  sudo criu-ns restore -vvvv --shell-job --log-file criu-restore.log --tcp-established --images-dir "$CRIU_IMAGE_DIR" &
}

is_app_ready() {
  check_response_code status 200
  return $?;
}

check_response_code() {
  local prefix="CHECK::APP"
  URL=http://$APP_HOST:$APP_HTTP_PORT/$1
  NEXT_WAIT_TIME=1
  MAX_WAIT_TIME=60
  SLEEP_TIME=0.25 # 250ms
  until [ $NEXT_WAIT_TIME -gt $MAX_WAIT_TIME ] || [ $(curl -s -o /dev/null -w "%{http_code}" $URL) == $2 ]
  do
    print_info "$prefix - Waiting for application to handle http traffic. Checking with url $URL. Check $NEXT_WAIT_TIME of $MAX_WAIT_TIME."
    sleep $SLEEP_TIME
    (( NEXT_WAIT_TIME++ ))
  done
  if [ $NEXT_WAIT_TIME -gt $MAX_WAIT_TIME ]
  then
    print_error "$prefix - Application is not ready to handle http traffic. Waited $MAX_WAIT_TIME x $SLEEP_TIME sec. Checked url was $URL."
    return 1;
  else
    local waited=$((NEXT_WAIT_TIME-1))
    print_info "$prefix - Application is ready to handle http traffic. Waited $waited x $SLEEP_TIME sec. Checked url was $URL."
    return 0;
  fi
}

is_database_ready() {
  local prefix="CHECK::DATABASE"
  NEXT_WAIT_TIME=1
  MAX_WAIT_TIME=60
  SLEEP_TIME=0.25 # 250ms
  until [ $NEXT_WAIT_TIME -gt $MAX_WAIT_TIME ] || docker exec -it $DOCKER_DATABASE_CONTAINER_NAME pg_isready --host=$DB_HOST --port=$DB_PORT --username=$RESOURCE_USER --dbname=$DB_NAME &>/dev/null
  do
    print_info "$prefix - Waiting for database connection to be available. Checking with host $DB_HOST, port $DB_PORT, user $RESOURCE_USER, database name $DB_NAME. Check $NEXT_WAIT_TIME of $MAX_WAIT_TIME."
    sleep $SLEEP_TIME
    (( NEXT_WAIT_TIME++ ))
  done
  if [ $NEXT_WAIT_TIME -gt $MAX_WAIT_TIME ]
  then
    print_error "$prefix - Database connection is not ready. Waited $MAX_WAIT_TIME x $SLEEP_TIME sec. Checked with host $DB_HOST, port $DB_PORT, user $RESOURCE_USER, database name $DB_NAME."
    return 1;
  else
    local waited=$((NEXT_WAIT_TIME-1))
    print_info "$prefix - Database connection is ready. Waited $waited x $SLEEP_TIME sec. Checking with host $DB_HOST, port $DB_PORT, user $RESOURCE_USER, database name $DB_NAME."
    return 0;
  fi
}

is_criu_available() {
  # false
  return 1;
}

# If you include this function in a another shell script and try using with criu it will fail. This has something todo with the fact that the script opens a new session (needs verification)
# To be able to use criu use this function directly after source functions.sh
# TODO: add check if criu is installed and ready to be used
app_run() {
  payara_kill
  is_criu_available
  local criu_available=$?
  if [ $criu_available -eq 0 ] && [ -d "$CRIU_IMAGE_DIR" ] && [ -d "$PAYARA_MICRO_ROOT_DIR" ]
	then
		app_restore
	else
    sudo rm -rf "$CRIU_IMAGE_DIR"
		payara_run
		is_app_ready
    local app_ready=$?
    if [ $criu_available -eq 0 ] && [ $app_ready -eq 0 ]
    then
      app_dump
		  app_restore
    fi
  fi
}

COLOR_GREEN='\033[1;34m'
COLOR_BROWN='\033[0;33m'
COLOR_RED='\033[0;31m'
FORMAT_BOLD='\033[1m'
FORMAT_RESET='\033[0m'

print_info() {
  echo -e "${COLOR_GREEN}[INFO]${FORMAT_RESET} ------------------------------------------------------------------------"
  echo -e "${COLOR_GREEN}[INFO]${FORMAT_RESET}${FORMAT_BOLD} $1 ${FORMAT_RESET}"
  echo -e "${COLOR_GREEN}[INFO]${FORMAT_RESET} ------------------------------------------------------------------------"
}

print_warn() {
  echo -e "${COLOR_BROWN}[WARNING]${FORMAT_RESET} ------"$PAYARA_MICRO_ROOT_DIR"------------------------------------------------------------------"
  echo -e "${COLOR_BROWN}[WARNING]${FORMAT_RESET}${FORMAT_BOLD} $1 ${FORMAT_RESET}"
  echo -e "${COLOR_BROWN}[WARNING]${FORMAT_RESET} ------------------------------------------------------------------------"
}

print_error() {
  echo -e "${COLOR_RED}[ERROR]${FORMAT_RESET} ------------------------------------------------------------------------"
  echo -e "${COLOR_RED}[ERROR]${FORMAT_RESET}${FORMAT_BOLD} $1 ${FORMAT_RESET}"
  echo -e "${COLOR_RED}[ERROR]${FORMAT_RESET} ------------------------------------------------------------------------"
}

setup_shortcuts() {
  echo 'TODO';
}
