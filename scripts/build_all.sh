#!/usr/bin/env bash

source common.sh || source scripts/common.sh || echo "No common.sh script found..."

ADDITIONAL_MAVEN_OPTS="${ADDITIONAL_MAVEN_OPTS:--Dspring.cloud.release.version=Brixton.BUILD-SNAPSHOT}"

set -e

build_app config-service $ADDITIONAL_MAVEN_OPTS
build_app edge-service $ADDITIONAL_MAVEN_OPTS
build_app eureka-service $ADDITIONAL_MAVEN_OPTS
build_app hystrix-dashboard $ADDITIONAL_MAVEN_OPTS
build_app quote-service $ADDITIONAL_MAVEN_OPTS