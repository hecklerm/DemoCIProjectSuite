#!/usr/bin/env bash

source common.sh || source scripts/common.sh || echo "No common.sh script found..."

set -e

clean_app config-service
clean_app edge-service
clean_app eureka-service
clean_app hystrix-dashboard
clean_app quote-service