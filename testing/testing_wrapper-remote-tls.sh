#!/bin/bash

echo "--Creating virtual environment--"
cd testing
virtualenv -q testing_venv
source testing_venv/bin/activate

echo "--Installing dependencies--"
pip3 install -q -r requirements_testing_wrapper_remote.txt

echo "--Setting execution environment--"
export DJANGO_BASE_URL="https://192.168.99.107:443/secure"
#Disabling TLS certificate validation due a self-signed certificate its used
export CURL_CA_BUNDLE=""

echo "--Running tests--"
python3 testing_requests.py

echo "--Cleaning up--"
deactivate
rm -rf testing_venv
cd ..
