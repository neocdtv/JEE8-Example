#!/bin/bash
source ./setup_vars.sh
rm -r /tmp/payaraMicroJEE8Example
java -XX:+UsePerfData -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address="$APP_DEBUG_PORT" -jar /var/tmp/payara-micro.jar --deploy app/target/app --nocluster --contextroot / --port "$APP_HTTP_PORT" --rootDir /tmp/payaraMicroJEE8Example

