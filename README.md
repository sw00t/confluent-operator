# Confluent Platform 5.5 Operator demo

Last updated: 8 July 2020


## Setup Kubernetes

```
minikube start --cpus=4 --memory=8G

kubectl version --short

# In separate terminal windows
minikube dashboard

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

```
# Watch the Kubernetes dashboard
```

## Validate the installation with Control Center

```
echo \
  $(kubectl get service controlcenter-0-internal \
      --output=jsonpath={'.status.loadBalancer.ingress[0].ip'} \
      --namespace=confluent) \
  controlcenter.confluent.platform.55.demo | sudo tee -a /etc/hosts  # TODO: need to update/correct functionality here. Manual works.

# controlcenter.confluent.platform.55.demo should refer to <controlcenter-0-internal Cluster IP>:9021

open http://controlcenter.confluent.platform.55.demo  # admin / Developer1

# Go to cluster -> topics -> /_confluent-metrics/message-viewer  # TODO: need to validate
```


## Confirm Operator is scoped to a single namespace

```
kubectl create namespace new-lob

helm install confluent-platform \
  $CPOPDIR/helm/confluent-operator \
  --values=/tmp/myvalues.yaml \
  --namespace=new-lob \
  --set zookeeper.enabled=true \
  --set global.provider.registry.credential.password=${JFROG_PASSWORD} \  # TODO: need to validate docker registry user info
  --set global.injectPullSecret=true

kubectl patch serviceaccount default \
  --namespace=new-lob \
  --patch='{"imagePullSecrets": [{"name": "confluent-docker-registry" }]}'

# Observe in the dashboard no ZooKeeper getting created
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
  --set operator.namespaced=false \
  --set global.provider.registry.credential.password=${JFROG_PASSWORD}  # TODO: need to validate docker registry user info

# Watch ZooKeeper eventually come up in the dashboard
```

## Clean up

```
# delete controlcenter.confluent.platform.55.demo entry in /etc/hosts
# stop processes for minikube dashboard and minikube tunnel windows
minikube delete
```


## Reference
# CP Operator QuickStart; scripted/simplified version
https://docs.confluent.io/current/installation/operator/co-quickstart.html
