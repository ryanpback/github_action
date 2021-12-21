#!/bin/bash

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ -z $4 ]; then
  echo "This script requires the following args - in order"
  echo -e "\t1.) Github API URL\n" \
          "\t2.) Github Repository\n" \
          "\t3.) Branch name for pull request into dmz" \
          "\t4.) Github OAuth Token"
  exit 1
fi

GITHUB_API=$1
REPO=$2
BRANCH=$3
TOKEN=$4

curl -s -I \
  -o /dev/null \
  -w "%{http_code}%" \
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


# echo "Response Code: $RESPONSE_CODE"

# if [ "$RESPONSE_CODE" = "201" ]; then
#   exit 0
# fi

echo "Something went wrong creating the pull request. Create a pull request from $BRANCH into DMZ."

exit 1
