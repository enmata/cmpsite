#!/bin/bash

#Runing sequentially tests agains DJANGO_BASE_URL from a temporal virtualenv checking the implemented API methods are working properly

echo "--Creating virtual environment--"
cd testing
virtualenv -q testing_venv
source testing_venv/bin/activate

echo "--Installing dependencies--"
pip3 install -q -r requirements_testing_wrapper_remote.txt

echo "--Setting execution environment--"
export DJANGO_BASE_URL="http://192.168.99.107:30008"

echo "--Running tests--"
python3 testing_requests.py

echo "--Cleaning up--"
deactivate
rm -rf testing_venv
cd ..
