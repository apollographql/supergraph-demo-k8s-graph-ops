#!/bin/bash

KUSTOMIZE_ENV="${1:-dev}"

echo "Using ${KUSTOMIZE_ENV}/kustomization.yaml"

kind --version

if [ $(kind get clusters | grep -E 'kind') ]
then
  kind delete cluster --name kind
fi

set -x

kind create cluster --image kindest/node:v1.21.1 --config=clusters/kind-cluster.yaml --wait 5m

flux install

flux create source git k8s-graph-ops \
  --url=https://github.com/apollographql/supergraph-demo-k8s-graph-ops.git \
  --branch=main

flux create kustomization infra \
  --namespace=default \
  --source=GitRepository/k8s-graph-ops.flux-system \
  --path="./infra/${KUSTOMIZE_ENV}" \
  --prune=true \
  --interval=1m \
  --validation=client

flux create kustomization subgraphs \
  --namespace=default \
  --source=GitRepository/k8s-graph-ops.flux-system \
  --path="./subgraphs/${KUSTOMIZE_ENV}" \
  --prune=true \
  --interval=1m \
  --validation=client

flux create kustomization router \
  --depends-on=infra \
  --namespace=default \
  --source=GitRepository/k8s-graph-ops.flux-system \
  --path="./router/${KUSTOMIZE_ENV}" \
  --prune=true \
  --interval=1m \
  --validation=client

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
