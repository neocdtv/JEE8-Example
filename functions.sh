source environment.sh
TMP_DIR="/var/tmp"
CRIU_IMAGE_DIR="$TMP_DIR/payaraMicroJEE8ExampleImage"
PAYARA_MICRO_ROOT_DIR="$TMP_DIR/payaraMicroJEE8Example"
PAYARA_VERSION="5.2020.3";
PAYARA_APP="$TMP_DIR/payara-micro-$PAYARA_VERSION.jar"
DOCKER_DATABASE_CONTAINER_NAME="jee8-example_database_1"
DOCKER_APP_CONTAINER_NAME="jee8-example_app_1"


database_build() {
  database_clean
  print_info "DATABASE::BUILD"
  docker-compose build database
}

database_run() {
  print_info "DATABASE::RUN"
  docker-compose up -d database
  is_database_ready
  mvn prepare-package flyway:migrate -f database/
}

database_clean() {
  print_info "DATABASE::CLEAN"
  docker kill $DOCKER_DATABASE_CONTAINER_NAME
  docker rm -f $DOCKER_DATABASE_CONTAINER_NAME
  docker rmi -f example/db
  mvn clean -f database/
}

app_clean() {
  print_info "APP::CLEAN"
  docker kill $DOCKER_APP_CONTAINER_NAME
  docker rm -f $DOCKER_APP_CONTAINER_NAME
  docker rmi -f example/app
  payara_kill
  mvn clean -f app/
}

app_build() {
  print_info "APP::BUILD"
  mvn clean -f app/
  app_rebuild
}

app_rebuild() {
  print_info "APP::REBUILD"
  mvn prepare-package war:exploded -Dmaven.test.skip -f app/
  app_redeploy
}

app_redeploy() {
  print_info "APP::REDEPLOY"
  # get status timestamp
  echo "" > app/target/app/.reload
  # wait for status timestamp to change
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
  local pid=`ps -aux | grep java | grep payara-micro | awk '{print $2}'`
  echo "$pid"
}

payara_run() {
  print_info "PAYARA::RUN"
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

clean_up() {
  sudo rm -fr "$CRIU_IMAGE_DIR"
  sudo rm -fr "$PAYARA_MICRO_ROOT_DIR"
}

payara_download() {
  print_info "PAYARA::DOWNLOAD"
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
  fi
}

# If you include this function in a another shell script and try using with criu it will fail. This has something todo with the fact that the script opens a new session (needs verification)
# To be able to use criu use this function directly after source functions.sh
app_run() {
  payara_kill
  if [ -d "$CRIU_IMAGE_DIR" ]
	then
		app_restore
	else
		payara_download
		payara_run
		is_app_ready # check return code and return if !=0
		app_dump
		app_restore
  fi
}

COLOR_GREEN='\033[1;34m'
COLOR_BROWN='\033[0;33m'#  
COLOR_RED='\033[0;31m'
FORMAT_BOLD='\033[1m'
FORMAT_RESET='\033[0m'

print_info() {
  echo -e "${COLOR_GREEN}[INFO]${FORMAT_RESET} ------------------------------------------------------------------------"
  echo -e "${COLOR_GREEN}[INFO]${FORMAT_RESET}${FORMAT_BOLD} $1 ${FORMAT_RESET}"
  echo -e "${COLOR_GREEN}[INFO]${FORMAT_RESET} ------------------------------------------------------------------------"
}

print_warn() {
  echo -e "${COLOR_BROWN}[WARNING]${FORMAT_RESET} ------------------------------------------------------------------------"
  echo -e "${COLOR_BROWN}[WARNING]${FORMAT_RESET}${FORMAT_BOLD} $1 ${FORMAT_RESET}"
  echo -e "${COLOR_BROWN}[WARNING]${FORMAT_RESET} ------------------------------------------------------------------------"
}

print_error() {
  echo -e "${COLOR_RED}[ERROR]${FORMAT_RESET} ------------------------------------------------------------------------"
  echo -e "${COLOR_RED}[ERROR]${FORMAT_RESET}${FORMAT_BOLD} $1 ${FORMAT_RESET}"
  echo -e "${COLOR_RED}[ERROR]${FORMAT_RESET} ------------------------------------------------------------------------"
}