#!/bin/bash

KUSTOMIZE_ENV="${1:-dev}"
ROLLOUT_STRATEGY="$2"

INFRA_ENV="${KUSTOMIZE_ENV}"
SUBGRAPHS_ENV="${KUSTOMIZE_ENV}"
ROUTER_ENV="${KUSTOMIZE_ENV}"

if [[ -n "$ROLLOUT_STRATEGY" ]]; then
  INFRA_ENV="${INFRA_ENV}"
  SUBGRAPHS_ENV="${SUBGRAPHS_ENV}-${ROLLOUT_STRATEGY}"
  ROUTER_ENV="${ROUTER_ENV}"
fi

echo "Using Kustomizations:"
echo "- infra/${INFRA_ENV}/kustomization.yaml"
echo "- subgraphs/${SUBGRAPHS_ENV}/kustomization.yaml"
echo "- router/${ROUTER_ENV}/kustomization.yaml"

kind --version

if [ $(kind get clusters | grep -E 'kind') ]
then
  kind delete cluster --name kind
fi
kind create cluster --image kindest/node:v1.21.1 --config=clusters/kind-cluster.yaml --wait 5m
