#!/bin/bash

COMMON_THINGS=(".scripts" ".github/workflows" "Makefile" "clusters/kind-cluster.yaml")

ENVIRONMENTS=("dev" "stage" "prod")
THINGS=("infra" "subgraphs" "router")

GITHUB_SHA="${GITHUB_SHA:-HEAD}"

if [[ "$1" != "local" ]]; then
  GITHUB_EVENT_BEFORE=${GITHUB_EVENT_BEFORE:-HEAD^}
fi

if [[ -n "$GITHUB_EVENT_BEFORE" ]]; then
  # only fetch in CI if not present
  if [[ "$(git cat-file -t $GITHUB_EVENT_BEFORE)" != "commit" ]]; then
    >&2 echo "fetching GITHUB_EVENT_BEFORE: $GITHUB_EVENT_BEFORE"
    git fetch origin $GITHUB_EVENT_BEFORE --depth=1
  fi
fi

>&2 echo "found GITHUB_EVENT_BEFORE: $GITHUB_EVENT_BEFORE"
>&2 echo "found GITHUB_SHA: $GITHUB_SHA"

# for dynamic build matrix in GitHub actions, see:
# https://github.community/t/check-pushed-file-changes-with-git-diff-tree-in-github-actions/17220/10

TMPFILE=$(mktemp)

cat >$TMPFILE <<EOF
{
  "include": [
EOF

>&2 echo "------------------------------"
>&2 echo "common changes"
>&2 echo "------------------------------"
COMMON_CHANGES=0
for thing in ${COMMON_THINGS[@]}; do
  DIFF=$( git diff --name-only $GITHUB_EVENT_BEFORE $GITHUB_SHA "./${thing}")
  if [[ -n "$DIFF" ]];  then
    COMMON_CHANGES=1
    >&2 echo "found common changes:"
    >&2 echo "$DIFF"
    >&2 echo "------------------------------"
  fi
done

for env in ${ENVIRONMENTS[@]}; do
  CHANGES=$COMMON_CHANGES

  >&2 echo "------------------------------"
  >&2 echo "$env changes"
  >&2 echo "------------------------------"

  for thing in ${things[@]}; do
    DIFF=$( git diff --name-only $GITHUB_EVENT_BEFORE $GITHUB_SHA "./${thing}")
    if [[ -n "$DIFF" ]];  then
      CHANGES=1

      >&2 echo "found ${thing}/${env} changes:"
      >&2 echo "$DIFF"
      >&2 echo "------------------------------"
    fi
  done

cat >>$TMPFILE <<EOF
  {
    "env": "$env",
    "changes": "$CHANGES"
  },
EOF

done

JSON="$(cat $TMPFILE)"

# remove trailing ','
if [[ $JSON == *, ]]; then
  JSON="${JSON%?}]}"
else
  JSON="${JSON}]}"
fi

echo $JSON

rm $TMPFILE
