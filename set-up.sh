#! /bin/bash

kind create cluster --name otel-hello-world --config config/kind-cluster-config.yaml

docker run -d --rm --name cloud-controller-manager --network kind -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.6.0 -enable-lb-port-mapping

helm install hello-world otel-hello-world --namespace monitoring --create-namespace

START_TIME=$(date +%s)
TIMEOUT=300

while [[ $(kubectl get pods -n monitoring --no-headers | grep -c 'Running') -lt $(kubectl get pods -n monitoring --no-headers | wc -l) ]]; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    
    if [[ $ELAPSED_TIME -ge $TIMEOUT ]]; then
        echo "Timeout reached: Not all pods in the monitoring namespace are ready."
        exit 1
    fi
    
    echo "Waiting for all pods in the monitoring namespace to be ready..."
    sleep 5
done

ENVOY_PORT=$(docker ps --format json | grep kindccm | jq -r '.Ports' | docker ps --format json | grep kindccm | jq -r '.Ports' | grep -oP '0\.0\.0\.0:\K\d+(?=->80/tcp)')

echo Grafana is available at http://localhost:"$ENVOY_PORT"