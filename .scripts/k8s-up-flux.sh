#!/bin/bash

source "$(dirname $0)/k8s-up-bare.sh"

set -x

flux install

flux create source git k8s-graph-ops \
  --url=https://github.com/apollographql/supergraph-demo-k8s-graph-ops.git \
  --branch=main

flux create kustomization infra \
  --namespace=default \
  --source=GitRepository/k8s-graph-ops.flux-system \
  --path="./infra/${INFRA_ENV}" \
  --prune=true \
  --interval=1m \
  --validation=client

flux create kustomization subgraphs \
  --namespace=default \
  --source=GitRepository/k8s-graph-ops.flux-system \
  --path="./subgraphs/${SUBGRAPHS_ENV}" \
  --prune=true \
  --interval=1m \
  --validation=client

flux create kustomization router \
  --depends-on=infra \
  --namespace=default \
  --source=GitRepository/k8s-graph-ops.flux-system \
  --path="./router/${ROUTER_ENV}" \
  --prune=true \
  --interval=1m \
  --validation=client

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
