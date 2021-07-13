#!/bin/bash

.scripts/k8s-up-flux.sh $1
.scripts/k8s-smoke.sh $1
code=$?
.scripts/k8s-down.sh
exit $code
