#!/bin/bash -x


minikube start --cpus=4 --memory=8G

export CPOPDIR=~/0/Confluent/Operator && echo $CPOPDIR

read -n 1 -r -s -p $'Run sudo minikube tunnel in a new term tab, then press enter to continue...\n'

read -n 1 -r -s -p $'Run minikube dashboard in a new term tab, then press enter to continue...\n'

#sudo minikube tunnel
#minikube dashboard

kubectl apply --filename $CPOPDIR/resources/crds/ && \
kubectl create namespace confluent && \
cp $CPOPDIR/helm/providers/swvalues.yaml /tmp/myvalues.yaml

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

echo "~5 min for CP components to deploy - monitor pods status in k8s dash or CLI"
echo "open C3"
