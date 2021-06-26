#!/bin/bash

env="${1:-dev}"
port="${2:-80}"

retry=60
code=1
until [[ $retry -le 0 || $code -eq 0 ]]
do
  kubectl get all
  ( cd ./test/${env}; ./smoke.sh $port )

  code=$?

  if [[ $code -eq 0 ]]
  then
    exit $code
  fi

  ((retry--))
  sleep 2
done

.scripts/k8s-nginx-dump.sh "smoke test failed"

.scripts/k8s-graph-dump.sh "smoke test failed"

exit $code
