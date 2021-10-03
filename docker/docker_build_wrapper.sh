#!/bin/bash

# Script building the necessary docker images on local docker deaemon for minikube environment

echo "--Setting environment--"
eval $(minikube docker-env)
export DOCKER_TLS_VERIFY=0
export DOCKER_HOST="tcp://127.0.0.1:2374"
alias docker='docker --tls'

echo "--Building images--"
cd docker
docker build -t cmpsite-init -f Dockerfile-init .
docker build -t cmpsite-run -f Dockerfile-run .

echo "--Pushing images--"
