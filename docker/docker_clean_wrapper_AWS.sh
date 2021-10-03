#!/bin/bash

# Script removing local Docker images on local docker deaemon aand also remobing AWS ECR registry
# Setting variables
export aws_region=eu-central-1
export aws_account_id=519159021228
export Docker_registry_name=cmpsite-registry
export Docker_image_name_1=cmpsite-init
export Docker_image_name_2=cmpsite-run

echo "--Cleaning up old images--"
docker image rm $Docker_image_name_1
docker image rm $Docker_image_name_1

#Deleting remote registry
aws ecr delete-repository  \
    --repository-name $Docker_registry_name --force
