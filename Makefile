.PHONY: default
default: demo

.PHONY: demo
demo: k8s-up-dev smoke k8s-down

.PHONY: k8s-up
k8s-up:
	.scripts/k8s-up.sh

.PHONY: k8s-up-dev
k8s-up-dev:
	.scripts/k8s-up.sh dev

.PHONY: k8s-up-stage
k8s-up-stage:
	.scripts/k8s-up.sh stage

.PHONY: k8s-up-prod
k8s-up-prod:
	.scripts/k8s-up.sh prod

.PHONY: query
query:
	.scripts/query.sh 80

.PHONY: smoke
smoke:
	.scripts/k8s-smoke.sh

.PHONY: smoke-dev
smoke-dev:
	.scripts/k8s-smoke.sh dev

.PHONY: smoke-stage
smoke-stage:
	.scripts/k8s-smoke.sh stage

.PHONY: smoke-prod
smoke-prod:
	.scripts/k8s-smoke.sh prod

.PHONY: k8s-nginx-dump
k8s-nginx-dump:
	.scripts/k8s-nginx-dump.sh "k8s-nginx-dump"

.PHONY: k8s-graph-dump
k8s-graph-dump:
	.scripts/k8s-graph-dump.sh "k8s-graph-dump"

.PHONY: k8s-down
k8s-down:
	.scripts/k8s-down.sh

.PHONY: k8s-ci
k8s-ci:
	@.scripts/k8s-ci.sh

.PHONY: k8s-ci-dev
k8s-ci-dev:
	@.scripts/k8s-ci.sh dev

.PHONY: k8s-ci-stage
k8s-ci-stage:
	@.scripts/k8s-ci.sh stage

.PHONY: k8s-ci-prod
k8s-ci-prod:
	@.scripts/k8s-ci.sh prod

.PHONY: dep-act
dep-act:
	curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s v0.2.23

ubuntu-latest=ubuntu-latest=catthehacker/ubuntu:act-latest

.PHONY: act
act:
	act -P $(ubuntu-latest) -W .github/workflows/main.yml --secret-file docker.secrets --detect-event

.PHONY: act-subgraph-publish
act-subgraph-publish:
	act -P $(ubuntu-latest) -W .github/workflows/subgraph-publish.yml --secret-file graph-api.env

.PHONY: act-supergraph-build-webhook
act-supergraph-build-webhook:
	act -P $(ubuntu-latest) -W .github/workflows/supergraph-build-webhook.yml --secret-file graph-api.env --detect-event

.PHONY: act-rebase
act-rebase:
	act -P $(ubuntu-latest) -W .github/workflows/rebase.yml -s GITHUB_TOKEN --secret-file docker.secrets --detect-event

.PHONY: docker-prune
docker-prune:
	.scripts/docker-prune.sh

.PHONY: fetch-dev
fetch-dev:
	.scripts/fetch.sh dev

.PHONY: fetch-stage
fetch-stage:
	.scripts/fetch.sh stage

.PHONY: fetch-prod
fetch-prod:
	.scripts/fetch.sh stage

.PHONY: promote-dev-stage
promote-dev-stage:
	cp infra/dev/kustomization.yaml infra/stage
	cp subgraphs/dev/kustomization.yaml subgraphs/stage
	cp router/dev/kustomization.yaml router/stage
	cp test/dev/smoke.sh test/stage

.PHONY: promote-stage-prod
promote-stage-prod:
	cp infra/stage/kustomization.yaml infra/prod
	cp subgraphs/stage/kustomization.yaml subgraphs/prod
	cp router/stage/kustomization.yaml router/prod
	cp test/stage/smoke.sh test/prod
