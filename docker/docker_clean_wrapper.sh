#!/bin/bash

# Script removing local Docker images on local docker deaemon for minikube environment

echo "--Setting environment--"
eval $(minikube docker-env)
export DOCKER_TLS_VERIFY=0
export DOCKER_HOST="tcp://127.0.0.1:2374"
alias docker='docker --tls'

echo "--Cleaning up old images--"
docker image rm cmpsite-init
docker image rm cmpsite-run
