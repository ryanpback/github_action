#!/bin/bash

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
  echo "This script requires the following args - in order"
  echo -e "\t1.) Github API URL\n" \
          "\t2.) Github Repository\n" \
          "\t3.) Branch name for pull request into dmz"
  exit 1
fi

GITHUB_API=$1
REPO=$2
BRANCH=$3
TOKEN=$4

curl -s -I \
  -o /dev/null \
  -w "%{http_code}" \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "authorization: Bearer $TOKEN" \
  "${GITHUB_API}/repos/${REPO}/pulls" \
  -d \
  '{
    "head": "'"$BRANCH"'",
    "base": "main",
    "title": "Merge '"$BRANCH"' into DMZ",
    "draft: "true"
  }'

echo $?

if [ "$?" = "201" ]; then
  exit 0
fi

exit 1
