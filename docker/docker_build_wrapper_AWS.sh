#!/bin/bash

# Script building and publishing the necessary docker images to a new ECR registry on AWS

# Setting variables
export aws_region=eu-central-1
export aws_account_id=XXX
export Docker_registry_name=cmpsite-registry
export Docker_registry_FQDN=$aws_account_id.dkr.ecr.$aws_region.amazonaws.com/$Docker_registry_name

export Docker_image_name_1=cmpsite-init
export Docker_image_file_1=Dockerfile-init

export Docker_image_name_2=cmpsite-run
export Docker_image_file_2=Dockerfile-run

# Creating ECR Docker registry
aws ecr create-repository \
     --repository-name $Docker_registry_name \
     --region $aws_region

# Building and tagging images
cd docker
docker build -t $Docker_image_name_1 -f $Docker_image_file_1 .
docker tag $Docker_image_name_1 $Docker_registry_FQDN:$Docker_image_name_1

docker build -t $Docker_image_name_2 -f $Docker_image_file_2 .
docker tag $Docker_image_name_2 $Docker_registry_FQDN:$Docker_image_name_2

# Logging in into the registry
aws ecr get-login-password \
    --region $aws_region \
| docker login \
    --username AWS \
    --password-stdin $aws_account_id.dkr.ecr.$aws_region.amazonaws.com

# Pushing the image to the registry
docker push $Docker_registry_FQDN:$Docker_image_name_1
docker push $Docker_registry_FQDN:$Docker_image_name_2
