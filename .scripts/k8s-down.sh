#!/bin/bash

# just delete the whole cluster
#kubectl delete -k router/dev
#kubectl delete -k subgraphs/dev
#kubectl delete -k infra/dev
kind delete cluster
