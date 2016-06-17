#!/usr/bin/env bash

clear

source common.sh || source scripts/common.sh || echo "No common.sh script found..."

set -e

echo -e "Update all submodules\n"
update_submodules

echo -e "Ensure that all the apps are built!\n"
build_all_apps

cat <<EOF
This Bash file will run all the apps required for the presentation.

NOTE:

- you need internet connection for the apps to download configuration from Github.
- you need docker-compose for RabbitMQ to start

We will do it in the following way:

01) Run config-server
02) Wait for the app (config-server) to boot (port: 8888)
03) Run eureka-service
04) Wait for the app (eureka-service) to boot (port: 8761)
05) Run hystrix-dashboard
06) Wait for the app (hystrix-dashboard) to boot (port: 8010)
07) Run reservation-client
08) Wait for the app (quote-service) to boot (port: 8088)
09) Wait for the app (quote-service) to register in Eureka Server
10) Run reservation-service
11) Wait for the app (edge-service) to boot (port: 8086)
12) Wait for the app (edge-service) to register in Eureka Server
13) curl --fail requests to quote-service
14) curl --fail requests to edge-service (check if Zuul and RabbitMQ is working fine)

EOF

echo "Ensure that apps are not running"
kill_all_apps

echo "Starting RabbitMQ on port 9672 with docker-compose"
docker-compose up -d || echo "RabbitMQ seems to be working already or some other exception occurred"

java_jar config-service
wait_for_app_to_boot_on_port 8888

java_jar eureka-service
wait_for_app_to_boot_on_port 8761

java_jar hystrix-dashboard
wait_for_app_to_boot_on_port 8010

java_jar quote-service
wait_for_app_to_boot_on_port 8088
check_app_presence_in_discovery QUOTE-SERVICE

java_jar edge-service
wait_for_app_to_boot_on_port 8086
check_app_presence_in_discovery EDGE-SERVICE

echo + quote-service endpoints
echo "\n"
echo ++ HAL Browser
curl --fail -X GET http://localhost:8088
echo "\n"
echo ++ All quotes
curl --fail -X GET http://localhost:8088/quotes
echo "\n"
echo ++ Random quote
curl --fail -X GET http://localhost:8088/random

echo "\n"
echo "\n"
echo + edge-service endpoints
echo "\n"
echo ++ Zuul microproxy passthroughs to quote-service
echo +++ All quotes
curl --fail -X GET http://localhost:8086/qs/quotes
echo "\n"
echo +++ Random quote
curl --fail -X GET http://localhost:8086/qs/random
echo "\n"
echo ++ Direct access to defined endpoint in edge-service
curl --fail -X GET http://localhost:8086/quotorama
echo "\n"
echo ++ Zuul route to defined endpoint, which then uses RestTemplate to access quote-service.
echo ++ NOTE: This is a contrived example I use to explain/demo how Zuul intelligent routing
echo ++       works. Although unorthodox, it is 100% compliant with the Spring Cloud Zuul
echo ++       documentation - up to and including June 15, 2016, at least.
curl --fail -X GET http://localhost:8086/quote
echo "\n"
echo ++ POST to /newquote for testing RabbitMQ
echo ++ NOTE: Must have a RabbitMQ instance running and code built with relevant code enabled.
curl --fail -X POST -H "Content-Type: application/json" -d '{"text":"Another test quote.","source":"Me"}' http://localhost:8086/newquote
echo "\n"

echo -e "All apps seem to be working!\n\n"
