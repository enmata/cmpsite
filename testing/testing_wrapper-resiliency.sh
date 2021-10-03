#!/bin/bash

# Killing the pod to test the recreation
echo "--Removing actual pod environment--"
export PODNAME=$(kubectl -n cmpsite-namespace get po -o=jsonpath='{.items[0].metadata.name}')
kubectl -n cmpsite-namespace delete pod $PODNAME
