# Supergraph Demo - GitOps Config Repo

This is the `config repo` for the [apollographq/supergraph-demo](https://github.com/apollographql/supergraph-demo) `source repo`.

![CI](https://github.com/prasek/supergraph-demo-gitops/actions/workflows/main.yml/badge.svg)

![Apollo Federation with Supergraphs](docs/media/supergraph.png)

## Welcome

This is the `config repo` for the [apollographq/supergraph-demo](https://github.com/apollographql/supergraph-demo) `source repo`.

It follows the [Declarative GitOps CD for Kubernetes Best Practices](https://argoproj.github.io/argo-cd/user-guide/best_practices/):

* `source repo`
  * [apollographq/supergraph-demo](https://github.com/apollographql/supergraph-demo) produces the artifacts:
  * subgraph docker images w/ embedded subgraph schemas
  * supergraph-router docker image that can be fed a composed supergraph schema via
    * (a) Apollo Uplink - for update in place
    * (b) via a `ConfigMap` for declarative k8s config management
  * CI:
    * builds/publishes container images to container registry
    * auto bumps version numbers
    * creates PRs to propagate candidate configs and version bumps to `config repo`

* `config repo`
  * has the full k8s configs for dev, stage, and prod environments:
    * cluster - base cluster & GitOps config
    * infra - nginx, etc.
    * router - supergraph router config
    * subgraphs - products, inventory, users
  * supports promoting config from dev -> stage -> prod
    * `make promote-dev-stage`
    * `make promote-stage-prod`

If you're not familiar with `kustomize` and k8s-native config management, checkout the following:

* [https://kustomize.io/](https://kustomize.io/).
* [kustomize helm example](https://github.com/fluxcd/flux2-kustomize-helm-example)
* [multi-tenancy example](https://github.com/fluxcd/flux2-multi-tenancy)
* [best-practices discussion thread](https://github.com/fluxcd/flux/issues/1071)

## Deploying a Graph Router to Kubernetes with kustomize

You'll need:

* [kubectl](https://kubernetes.io/docs/tasks/tools/) - with expanded `kustomize` support for `resources`
* [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

then run:

```sh
make demo-k8s
```

which creates:

* local k8s cluster with the NGINX Ingress Controller
* graph-router `Deployment` configured to use a supergraph `ConfigMap`
* graph-router `Service` and `Ingress`

and applies the following:

```
kubectl apply -k infra/dev
kubectl apply -k subgraphs/dev
kubectl apply -k router/dev
```

using [router/base/router.yaml](router/base/router.yaml):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: router
  name: router-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: router
  template:
    metadata:
      labels:
        app: router
    spec:
      containers:
      - env:
        - name: APOLLO_SCHEMA_CONFIG_EMBEDDED
          value: "true"
        image: prasek/supergraph-router:latest
        name: router
        ports:
        - containerPort: 4000
        volumeMounts:
        - mountPath: /etc/config
          name: supergraph-volume
      volumes:
      - configMap:
          name: supergraph-c22698b7b9
        name: supergraph-volume
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: supergraph-c22698b7b9
data:
  supergraph.graphql: |
    schema
      @core(feature: "https://specs.apollo.dev/core/v0.1"),
      @core(feature: "https://specs.apollo.dev/join/v0.1")
    {
      query: Query
    }

    ...

    enum join__Graph {
      INVENTORY @join__graph(name: "inventory" url: "http://inventory:4000/graphql")
      PRODUCTS @join__graph(name: "products" url: "http://products:4000/graphql")
      USERS @join__graph(name: "users" url: "https://users:4000/graphql")
    }

    type Product
      @join__owner(graph: PRODUCTS)
      @join__type(graph: PRODUCTS, key: "id")
      @join__type(graph: PRODUCTS, key: "sku package")
      @join__type(graph: PRODUCTS, key: "sku variation{id}")
      @join__type(graph: INVENTORY, key: "id")
    {
      id: ID! @join__field(graph: PRODUCTS)
      sku: String @join__field(graph: PRODUCTS)
      package: String @join__field(graph: PRODUCTS)
      variation: ProductVariation @join__field(graph: PRODUCTS)
      dimensions: ProductDimension @join__field(graph: PRODUCTS)
      createdBy: User @join__field(graph: PRODUCTS, provides: "totalProductsCreated")
      delivery(zip: String): DeliveryEstimates @join__field(graph: INVENTORY, requires: "dimensions{size weight}")
    }

    type ProductDimension {
      size: String
      weight: Float
    }

    type ProductVariation {
      id: ID!
    }

    type Query {
      allProducts: [Product] @join__field(graph: PRODUCTS)
      product(id: ID!): Product @join__field(graph: PRODUCTS)
    }

    type User
      @join__owner(graph: USERS)
      @join__type(graph: USERS, key: "email")
      @join__type(graph: PRODUCTS, key: "email")
    {
      email: ID! @join__field(graph: USERS)
      name: String @join__field(graph: USERS)
      totalProductsCreated: Int @join__field(graph: USERS)
    }
---
apiVersion: v1
kind: Service
metadata:
  name: router-service
spec:
  ports:
  - port: 4000
    protocol: TCP
    targetPort: 4000
  selector:
    app: router
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: router-ingress
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: router-service
            port:
              number: 4000
        path: /
        pathType: Prefix
```

and 3 subgraph services [subgraphs/base/subgraphs.yaml](subgraphs/base/subgraphs.yaml):

`make demo-k8s` then runs the following in a loop until the query succeeds or 2 min timeout:

```sh
kubectl get all
make k8s-query
```

which shows the following:

```
NAME                                     READY   STATUS    RESTARTS   AGE
pod/inventory-65494cbf8f-bhtft           1/1     Running   0          59s
pod/products-6d75ff449c-9sdnd            1/1     Running   0          59s
pod/router-deployment-84cbc9f689-8fcnf   1/1     Running   0          20s
pod/users-d85ccf5d9-cgn4k                1/1     Running   0          59s

NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/inventory        ClusterIP   10.96.108.120   <none>        4000/TCP   59s
service/kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP    96s
service/products         ClusterIP   10.96.65.206    <none>        4000/TCP   59s
service/router-service   ClusterIP   10.96.178.206   <none>        4000/TCP   20s
service/users            ClusterIP   10.96.98.53     <none>        4000/TCP   59s

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/inventory           1/1     1            1           59s
deployment.apps/products            1/1     1            1           59s
deployment.apps/router-deployment   1/1     1            1           20s
deployment.apps/users               1/1     1            1           59s

NAME                                           DESIRED   CURRENT   READY   AGE
replicaset.apps/inventory-65494cbf8f           1         1         1       59s
replicaset.apps/products-6d75ff449c            1         1         1       59s
replicaset.apps/router-deployment-84cbc9f689   1         1         1       20s
replicaset.apps/users-d85ccf5d9                1         1         1       59s
Smoke test
-------------------------------------------------------------------------------------------
++ curl -X POST -H 'Content-Type: application/json' --data '{ "query": "{ allProducts { id, sku, createdBy { email, totalProductsCreated } } }" }' http://localhost:80/
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   352  100   267  100    85   3000    955 --:--:-- --:--:-- --:--:--  3911
{"data":{"allProducts":[{"id":"apollo-federation","sku":"federation","createdBy":{"email":"support@apollographql.com","totalProductsCreated":1337}},{"id":"apollo-studio","sku":"studio","createdBy":{"email":"support@apollographql.com","totalProductsCreated":1337}}]}}
Success!
-------------------------------------------------------------------------------------------
```

`make demo-k8s` then cleans up:

```
deployment.apps "graph-router" deleted
service "graphql-service" deleted
ingress.networking.k8s.io "graphql-ingress" deleted
Deleting cluster "kind" ...
```

## Learn More

Checkout the [apollographq/supergraph-demo](https://github.com/apollographql/supergraph-demo) `code repo`.

Learn more about how Apollo can help your teams ship faster here: https://www.apollographql.com/docs/studio/.
