# Confluent Platform 5.5 Operator on Minikube demo

Last updated: 17 July 2020
Versions tested: minikube v1.11.0, kubernetes v1.18.3, docker 19.03.8

## Setup Kubernetes
```
minikube start --cpus=4 --memory=8G
```
```
kubectl version --short
```

# In separate terminal windows
```
minikube dashboard
```
```
sudo minikube tunnel
```

## Download a recent nighly build of the Operator bundle

```
# Sign into the AWS Dev tile in Okta and go to:
#   https://s3.console.aws.amazon.com/s3/buckets/platform-ops-bin/operator/?region=us-west-2&tab=overview
```

## cd into the Operator demo dir
```
export CPOPDIR=~/0/Confluent/Operator
```

## Extend Kubernetes with first class CP primitives

```
kubectl apply --filename $CPOPDIR/resources/crds/
```

## Create a Kubernetes namespace to install Operator and CP

```
kubectl create namespace confluent
```

## Configure and deploy Operator and CP

```
cp $CPOPDIR/helm/providers/private.yaml /tmp/myvalues.yaml

vi /tmp/myvalues.yaml  # make necessary changes

vimdiff /tmp/values.yaml $CPOPDIR/helm/providers/private.yaml

helm install confluent-platform \
  $CPOPDIR/helm/confluent-operator/ \
  --values=/tmp/myvalues.yaml \
  --namespace=confluent \
  --set operator.enabled=true \
  --set zookeeper.enabled=true \
  --set kafka.enabled=true \
  --set controlcenter.enabled=true

kubectl patch serviceaccount default \
  --namespace=confluent \
  --patch='{"imagePullSecrets": [{"name": "confluent-docker-registry" }]}'
```

## Wait for CP to start up

# Watch the pods spin up
```
watch kubectl get po -n confluen
```

## Validate the installation with Control Center

```
sudo bash -c 'echo $(kubectl get svc controlcenter-0-internal -n confluent --output=jsonpath='{.spec.clusterIP}') controlcenter.confluent.platform.55.demo >> /etc/hosts'
```
```
open http://controlcenter.confluent.platform.55.demo:9021
```
u/p admin / Developer1


In the C3 URL, navigate to Consumers, `_confluent-controlcenter-0`, `_confluent-metrics`, then Messages



## Confirm Operator is scoped to a single namespace

```
kubectl create namespace new-lob

helm install confluent-platform \
  $CPOPDIR/helm/confluent-operator \
  --values=/tmp/myvalues.yaml \
  --namespace=new-lob \
  --set zookeeper.enabled=true \
  --set global.injectPullSecret=true

kubectl patch serviceaccount default \
  --namespace=new-lob \
  --patch='{"imagePullSecrets": [{"name": "confluent-docker-registry" }]}'
```
# Observe a new ZooKeeper cluster being created in the new-lob namespace
```
kubectl get po -n new-lob
```


## Expand Operator to serve all namespaces
```
helm upgrade confluent-platform \
  $CPOPDIR/helm/confluent-operator/ \
  --values=/tmp/myvalues.yaml \
  --namespace=confluent \
  --set operator.enabled=true \
  --set zookeeper.enabled=true \
  --set kafka.enabled=true \
  --set controlcenter.enabled=true \
  --set operator.namespaced=false
```

# Observe ZooKeeper come up in the dashboard/StatefulSets
```
kubectl get po --all-namespaces
```

## Clean up

```
# delete controlcenter.confluent.platform.55.demo entry in /etc/hosts
# stop processes for minikube dashboard and minikube tunnel windows
minikube delete
```


Ref
https://docs.confluent.io/current/installation/operator/co-quickstart.html
https://gist.github.com/amitkgupta/e3296bc9b0ed0dfb50248d1d29d680bf
