#!/bin/bash
set -e

function waitForResult () {
  echo "Waiting for tests to finish execution.."
  for ((i=1;i<=100;i++));
  do
    sleep 20s;
    get_build_status="$(curl -u $browserstack_username:$browserstack_access_key -X GET "https://api-cloud.browserstack.com/app-automate/espresso/v2/builds/$browserstack_build_id")"
    build_status=$(echo "$get_build_status" | jq .status | sed 's/"//g')
    echo "$build_status"

    if [[ $build_status == "passed" ]] ; then
      session_id=$(echo "$get_build_status" | jq ".devices[0] .sessions[0] .id" | sed 's/"//g')
      fetchBuildSession "$browserstack_build_id" "$session_id"
      break
    fi

#    if [[ $build_status != "running" ]] ; then
#      echo "Checking Test Results..."
#      break
#    fi
  done
}

function fetchBuildSession () {
  get_session_status="$(curl -u $browserstack_username:$browserstack_access_key -X GET "https://api-cloud.browserstack.com/app-automate/espresso/v2/builds/$1/sessions/$2")"
  session_status=$(echo -n "$get_build_status" | jq .status | sed 's/"//g')
  echo "$session_status"
  listTestcasesData "$get_session_status"
}

function listTestcasesData () {
  for row in $(echo "$1" | jq -r '.testcases.data | .[] | @base64');
  do
    _jq() {
      echo ${row} | jq -R -r "@base64d | ${1}"
      echo
    }
    echo $(_jq '.')
  done
}

echo "username:$browserstack_username"
echo "access_key:$browserstack_access_key"
echo "build_id:$browserstack_build_id"
waitForResult