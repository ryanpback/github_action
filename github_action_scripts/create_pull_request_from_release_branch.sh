#!/bin/bash

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ -z $4 ]; then
  echo "This script requires the following args - in order"
  echo -e "\t1.) Github API URL\n" \
          "\t2.) Github Repository\n" \
          "\t3.) Branch name for pull request into dmz\n" \
          "\t4.) Github OAuth Token"
  exit 1
fi

# Args passed to script
GITHUB_API_URL=$1
REPO=$2
RELEASE_BRANCH=$3
ACCESS_TOKEN=$4

# Text colors
BLUE="\033[34m"
YELLOW="\033[33m"
GREEN="\033[32m"
RED="\033[31m"
END_COLOR="\033[0m"

# Curl Vars
BASE_BRANCH=main
AUTH_HEADER="authorization: Bearer $ACCESS_TOKEN"
BASE_URL="$GITHUB_API_URL/repos/$REPO"
ACCEPT_HEADER="Accept: application/vnd.github.v3+json"

create_pull_request() {
  echo -e "\n${BLUE}Creating Pull Request from $RELEASE_BRANCH into DMZ...${END_COLOR}"

  ret_val=$(curl -s \
    -w "%{http_code}" \
    -X POST \
    -H "$ACCEPT_HEADER" \
    -H "$AUTH_HEADER" \
    "$BASE_URL/pulls" \
    -d \
    '{
      "head": "'"$RELEASE_BRANCH"'",
      "base": "'"$BASE_BRANCH"'",
      "title": "Merge '"$RELEASE_BRANCH"' into '"$BASE_BRANCH"'",
      "draft": "true"
    }'
  )
}

get_pulls() {
  echo -e "${BLUE}Retrieving Pull Requests...${END_COLOR}"

  ret_val=$(curl -s \
    -H "$ACCEPT_HEADER" \
    -H "$AUTH_HEADER" \
    "$BASE_URL/pulls?head=$RELEASE_BRANCH&base=$BASE_BRANCH"
  )
}

get_contributors_for_branch() {
  echo -e "\n${BLUE}Retrieving Contributors to $RELEASE_BRANCH...${END_COLOR}"

  ret_val=$(curl -s \
    -H "$ACCEPT_HEADER" \
    -H "$AUTH_HEADER" \
    "$BASE_URL/commits?sha=$RELEASE_BRANCH"
  )
}

request_reviews_for_pr() {
  echo -e "\n${BLUE}Requesting Reviews...${END_COLOR}"
  pr_number=$1
  reviewers=$2

  ret_val=$(curl -s \
    -X POST \
    -H "$ACCEPT_HEADER" \
    -H "$AUTH_HEADER" \
    "$BASE_URL/pulls/$pr_number/requested_reviewers" \
    -d \
    '{
      "reviewers": ["'"$reviewers"'"]
    }'
  )
}

# Start script
create_pull_request

http_code=$(tail -n1 <<< "$ret_val")
content=$(sed '$ d' <<< "$ret_val")

if [ "$http_code" = "201" ]; then
  echo -e "\n${GREEN}Pull Request from $RELEASE_BRANCH"\
            "into $BASE_BRANCH successfully created.${END_COLOR}"

  pull_number=$(echo $content | jq '.number')

  get_contributors_for_branch
  contributors=$(echo $ret_val | jq -r '. | map(.author?.login) | unique | join(",")')

  request_reviews_for_pr $pull_number $contributors

  echo -e "\n${GREEN}Requested reviews from the following" \
          "contributors: $contributors"

  exit 0
fi


error_message=$(echo $content | jq '.errors[0].message')

# 422 is the response code if a PR from Head into Base already exists
if [ "$http_code" = "422" ]; then
  get_pulls
  PR_URL=$(echo $ret_val | jq '.[0].url')

  echo -e "\n${YELLOW}$error_message. See: $PR_URL${END_COLOR}"
  exit 0
fi

echo content | jq '.'
echo -e "\n${RED}$error_message." \
        "Please create a pull request merging $RELEASE_BRANCH into $BASE_BRANCH${END_COLOR}"
exit 1
