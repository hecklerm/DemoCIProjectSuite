#!/usr/bin/env bash

set -e

WAIT_TIME="${WAIT_TIME:-5}"
RETRIES="${RETRIES:-10}"
SERVICE_PORT="${SERVICE_PORT:-8081}"
TEST_ENDPOINT="${TEST_ENDPOINT:-check}"
JAVA_PATH_TO_BIN="${JAVA_HOME}/bin/"
if [[ -z "${JAVA_HOME}" ]] ; then
    JAVA_PATH_TO_BIN=""
fi
BUILD_FOLDER="${BUILD_FOLDER:-target}" #target - maven, build - gradle
PRESENCE_CHECK_URL="${PRESENCE_CHECK_URL:-http://localhost:8761/eureka/apps}"
HEALTH_HOST="${DEFAULT_HEALTH_HOST:-localhost}" #provide DEFAULT_HEALT HOST as host of your docker machine
RABBIT_MQ_PORT="${RABBIT_MQ_PORT:-9672}"
SYSTEM_PROPS="-Dspring.rabbitmq.host=${HEALTH_HOST} -Dspring.rabbitmq.port=${RABBIT_MQ_PORT}"

# ${RETRIES} number of times will try to curl to /health endpoint to passed port $1 and localhost
function wait_for_app_to_boot_on_port() {
    curl_health_endpoint $1 "127.0.0.1"
}

# ${RETRIES} number of times will try to curl to /health endpoint to passed port $1 and host $2
function curl_health_endpoint() {
    local PASSED_HOST="${2:-$HEALTH_HOST}"
    local READY_FOR_TESTS=1
    for i in $( seq 1 "${RETRIES}" ); do
        sleep "${WAIT_TIME}"
        curl -m 5 "${PASSED_HOST}:$1/health" && READY_FOR_TESTS=0 && break
        echo "Fail #$i/${RETRIES}... will try again in [${WAIT_TIME}] seconds"
    done
    return $READY_FOR_TESTS
}

# Check the app $1 (in capital)
function check_app_presence_in_discovery() {
    echo -e "\n\nChecking for the presence of $1 in Service Discovery for [$(( WAIT_TIME * RETRIES ))] seconds"
    READY_FOR_TESTS="no"
    for i in $( seq 1 "${RETRIES}" ); do
        sleep "${WAIT_TIME}"
        curl -m 5 $PRESENCE_CHECK_URL | grep $1 && READY_FOR_TESTS="yes" && break
        echo "Fail #$i/${RETRIES}... will try again in [${WAIT_TIME}] seconds"
    done
    if [[ "${READY_FOR_TESTS}" == "yes" ]] ; then
        return 0
    else
        return 1
    fi
}

# Runs the `java -jar` for given application $1 and system properties $2
function java_jar() {
    echo -e "\n\nStarting app $1 \n"
    local APP_JAVA_PATH=$1/${BUILD_FOLDER}
    local EXPRESSION="nohup ${JAVA_PATH_TO_BIN}java $2 $SYSTEM_PROPS -jar $APP_JAVA_PATH/*.jar >$APP_JAVA_PATH/nohup.log &"
    echo -e "\nTrying to run [$EXPRESSION]"
    eval $EXPRESSION
    pid=$!
    echo $pid > $APP_JAVA_PATH/app.pid
    echo -e "[$1] process pid is [$pid]"
    echo -e "System props are [$2]"
    echo -e "Logs are under [$APP_JAVA_PATH/nohup.log]\n"
    return 0
}

function build_app() {
    echo -e "Building app [$1] with options [$2]"
    cd $1
    local MVNW_PRESENT="no"
    ./mvnw --version && MVNW_PRESENT="yes" || echo "You don't have Maven wrapper... will try to run Maven instead"
    if [[ "${MVNW_PRESENT}" == "yes" ]] ; then
        ./mvnw clean package -T 6 $2
    else
        mvn clean package -T 6 $2
    fi
    cd $ROOT_FOLDER
}

function clean_app() {
    echo -e "Cleaning app [$1]"
    cd $1
    local MVNW_PRESENT="no"
    ./mvnw --version && MVNW_PRESENT="yes" || echo "You don't have Maven wrapper... will try to run Maven instead"
    if [[ "${MVNW_PRESENT}" == "yes" ]] ; then
        ./mvnw clean
    else
        mvn clean
    fi
    cd $ROOT_FOLDER
}

# Kills an app with given $1 version
function kill_app() {
    echo -e "Killing app $1"
    pkill -f "$1" && echo "Killed $1" || echo "$1 was not running"
    echo -e ""
    return 0
}

function build_all_apps() {
    ${ROOT_FOLDER}/scripts/build_all.sh
}

function update_submodules() {
    ${ROOT_FOLDER}/scripts/setup_repos.sh
}

# Kill all the apps
function kill_all_apps() {
    ${ROOT_FOLDER}/scripts/kill_all.sh
}

export WAIT_TIME
export RETIRES
export SERVICE_PORT

export -f wait_for_app_to_boot_on_port
export -f curl_health_endpoint
export -f java_jar
export -f build_all_apps
export -f kill_app
export -f kill_all_apps
export -f check_app_presence_in_discovery
export -f update_submodules
export -f build_app

ROOT_FOLDER=`pwd`
if [[ ! -e "${ROOT_FOLDER}/.git" ]]; then
    cd ..
    ROOT_FOLDER=`pwd`
    if [[ ! -e "${ROOT_FOLDER}/.git" ]]; then
        echo "No .git folder found"
        exit 1
    fi
fi

mkdir -p ${ROOT_FOLDER}/${BUILD_FOLDER}