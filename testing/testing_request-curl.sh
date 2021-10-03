#!/bin/bash

export BASE_URL="http://192.168.99.107:30008"
export BASE_URL_TLS="https://192.168.99.107:443/secure"
export CURL_CA_BUNDLE=""

function test_01_ready {
  echo "--Checking test_01_ready--"
  curl -sS -X GET $BASE_URL/user/  2> /dev/null
  echo $?
  curl -sS --insecure -X GET $BASE_URL_TLS/user/ 2> /dev/null
  echo $?
}
function test_02_insert {
  echo "--Checking test_02_insert--"
  curl -sS -X POST -H "Accept: Application/json" -H "Content-Type: application/json" -d '{"name":"ThisIsMyNameJSON"}' $BASE_URL/user/ 2> /dev/null
  echo $?
  curl -sS --insecure -X POST -H "Accept: Application/json" -H "Content-Type: application/json" -d '{"name":"ThisIsMyNameJSON"}' $BASE_URL_TLS/user/ 2> /dev/null
  echo $?
}
function test_03_getonesuer {
  echo "--Checking test_03_getonesuer--"
  curl -sS -X GET $BASE_URL/user/1/ 2> /dev/null
  echo $?
  curl -sS --insecure -X GET $BASE_URL_TLS/secure/user/ 2> /dev/null
  echo $?
}
function test_04_delete_exist {
  echo "--Checking test_04_delete_exist--"
  curl -sS -X DELETE $BASE_URL/user/1/ 2> /dev/null
  echo $?
  curl -sS --insecure -X GET $BASE_URL_TLS/secure/user/1/ 2> /dev/null
  echo $?
}
function test_05_delete_doesntexist {
  echo "--Checking test_05_delete_doesntexist--"
  curl -sS -X DELETE $BASE_URL/user/3/ 2> /dev/null
  echo $?
  curl -sS --insecure -X GET $BASE_URL_TLS/user/3/ 2> /dev/null
  echo $?
}
function test_06_method_no_exist {
  echo "--Checking test_06_method_no_exist--"
  curl -sS -X GET $BASE_URL/fakemethod/ 2> /dev/null
  echo $?
  curl -sS --insecure -X GET $BASE_URL_TLS/fakemethod/ 2> /dev/null
  echo $?
}
function test_07_heathcheck {
  echo "--Checking test_07_heathcheck--"
  curl -sS -X GET $BASE_URL/hc/?format=json 2> /dev/null
  echo $?
  curl -sS --insecure -X GET $BASE_URL_TLS/hc/?format=json 2> /dev/null
  echo $?
}

test_01_ready
test_02_insert
test_03_getonesuer
test_04_delete_exist
test_05_delete_doesntexist
test_06_method_no_exist
test_07_heathcheck
