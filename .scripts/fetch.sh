#!/bin/bash

GRAPH_VARIANT="${1:-dev}"

source "$(dirname $0)/get-env.sh"

( set -x; rover supergraph fetch supergraph-router@${GRAPH_VARIANT} > ./router/${GRAPH_VARIANT}/supergraph.graphql )
