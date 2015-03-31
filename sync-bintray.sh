#!/usr/bin/env bash

API_HOST=api.bintray.com
BASE_URL=https://${API_HOST}/content/pantsbuild/maven/repo
VERSION=0.0.1

URL=${BASE_URL}/${VERSION}

function publish {
  curl \
    --fail \
    --netrc \
    --data "$1" \
    ${URL}/publish &> /dev/null
}

FINALIZED=

function finalize {
  echo "Publishing uploaded artifacts..."
  publish && FINALIZED=true
}

function discard {
  if [[ -z "${FINALIZED}" ]]
  then
    echo -e "\nDiscarding uploaded artifacts..."
    publish '{"discard": true}'
  fi
}

function check_netrc {
  [[ -f ~/.netrc && -n "$(grep -E "^\s*machine\s+${API_HOST}\s*$" ~/.netrc)" ]]
}

if ! check_netrc
then
  echo "In order to publish bintray binaries you need an account"
  echo "with membership in the pantsbuild org [1]."
  echo
  echo "This account will need to be added to a ~/.netrc entry as follows:"
  echo 
  echo "machine ${API_HOST}"
  echo "  login <bintray username>"
  echo "  password <bintray api key [2]>"
  echo
  echo "[1] https://bintray.com/pantsbuild"
  echo "[2] https://bintray.com/docs/interacting/interacting_apikeys.html"
  exit 1
fi

trap "discard" EXIT

files=($(find . -mindepth 2 \! -wholename "./.git/*"))
count=${#files[@]}

echo "Uploading ${count} files to https://dl.bintray.com/pantsbuild/maven"
echo
echo "Press CTRL-C at any time to discard the uploaded artifacts; otherwise,"
echo "the artifacts will be finalized and published en-masse just before the"
echo "script completes."
echo

for i in $(seq 1 ${count})
do
  file=${files[$((i-1))]}
  echo "[${i}/${count}] Uploading ${file}"
  curl \
    --fail \
    --netrc \
    --upload-file ${file} \
    -o /dev/null \
    --progress-bar \
    -# \
    "${URL}/${file}?override=1" || \
  exit 1
  echo
done

finalize
