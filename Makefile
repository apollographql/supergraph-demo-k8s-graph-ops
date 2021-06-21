.PHONY: default
default: demo-k8s

.PHONY: demo-k8s
demo-k8s: k8s-up k8s-smoke k8s-down

.PHONY: publish
publish:
	.scripts/publish.sh

.PHONY: unpublish
unpublish:
	.scripts/unpublish.sh

.PHONY: graph-api-env
graph-api-env:
	@.scripts/graph-api-env.sh

.PHONY: k8s-config
k8s-config:
	.scripts/k8s-router-config.sh

.PHONY: k8s-up
k8s-up:
	.scripts/k8s-up.sh

.PHONY: k8s-query
k8s-query:
	.scripts/query.sh 80

.PHONY: k8s-smoke
k8s-smoke:
	.scripts/k8s-smoke.sh 80

.PHONY: k8s-nginx-dump
k8s-nginx-dump:
	.scripts/k8s-nginx-dump.sh "k8s-nginx-dump"

.PHONY: k8s-graph-dump
k8s-graph-dump:
	.scripts/k8s-graph-dump.sh "k8s-graph-dump"

.PHONY: k8s-down
k8s-down:
	.scripts/k8s-down.sh

.PHONY: ci-k8s
ci-k8s:
	@.scripts/ci-k8s.sh

.PHONY: dep-act
dep-act:
	curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s v0.2.23

.PHONY: act
act:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 -W .github/workflows/main.yml -j k8s --secret-file docker.secrets

.PHONY: act-subgraph-publish
act-subgraph-publish:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 -W .github/workflows/subgraph-publish.yml --secret-file graph-api.env

.PHONY: act-supergraph-build-webhook
act-supergraph-build-webhook:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 -W .github/workflows/supergraph-build-webhook.yml -s GITHUB_TOKEN --secret-file graph-api.env --detect-event

.PHONY: act-rebase
act-rebase:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 -W .github/workflows/rebase.yml -s GITHUB_TOKEN --secret-file docker.secrets --detect-event

.PHONY: docker-prune
docker-prune:
	.scripts/docker-prune.sh
