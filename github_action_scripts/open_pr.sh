#!/bin/bash

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ -z $4 ]; then
  echo "This script requires the following args - in order"
  echo -e "\t1.) Github API URL\n" \
          "\t2.) Github Repository\n" \
          "\t3.) Branch name for pull request into dmz" \
          "\t4.) Github OAuth Token"
  exit 1
fi

GITHUB_API_URL=$1
REPO=$2
RELEASE_BRANCH=$3
ACCESS_TOKEN=$4

BASE_BRANCH=main
BLUE="\033[34m"
YELLOW="\033[33m"
GREEN="\033[32m"
RED="\033[31m"
END_COLOR="\033[0m"

echo -e "\n${BLUE}Creating Pull Request from $RELEASE_BRANCH into DMZ${END_COLOR}\n"

response=$(curl -s \
  -w "%{http_code}" \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "authorization: Bearer $ACCESS_TOKEN" \
  "$GITHUB_API_URL/repos/$REPO/pulls" \
  -d \
  '{
    "head": "'"$RELEASE_BRANCH"'",
    "base": "'"$BASE_BRANCH"'",
    "title": "Merge '"$RELEASE_BRANCH"' into '"$BASE_BRANCH"'",
    "draft": "true"
  }'
)

http_code=$(tail -n1 <<< "$response")
content=$(sed '$ d' <<< "$response")

if [ "$http_code" = "201" ]; then
  echo -e "${GREEN}Pull Request from $RELEASE_BRANCH into $BASE_BRANCH successfully created.${END_COLOR}"
  exit 0
fi

error_message=$(echo $content | jq '.errors[0].message')

# 422 is the response code if a PR from Head into Base already exists
if [ "$http_code" = "422" ]; then
  PULLS=$(curl \
    -H "Accept: application/vnd.github.v3+json" \
    -H "authorization: Bearer $ACCESS_TOKEN" \
    "$GITHUB_API_URL/repos/$REPO/pulls?head=$RELEASE_BRANCH&base=$BASE_BRANCH"
  )
  PR_URL=$(echo $PULLS | jq '.[0].url')

  echo -e "${YELLOW}$error_message. See: $PR_URL${END_COLOR}"
  exit 0
fi

echo content | jq '.'
echo -e "${RED}$error_message." \
        "Please create a pull request merging $RELEASE_BRANCH into $BASE_BRANCH${END_COLOR}"
exit 1
