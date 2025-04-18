#! /bin/bash

echo Creating kind cluster...
kind create cluster --name otel-hello-world --config config/kind-cluster-config.yaml

# Cloud control manager is required to map grafana service port to localhost port
echo Starting cloud-controller-manager container
docker run -d --rm --name cloud-controller-manager --network kind -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.6.0 -enable-lb-port-mapping

echo Adding required helm repos
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo Installing otel-hello-world chart
helm dependency update otel-hello-world
helm install hello-world otel-hello-world --namespace observability --create-namespace

START_TIME=$(date +%s)
TIMEOUT=300

while [[ $(kubectl get pods -n observability --no-headers | grep -c 'Running') -lt $(kubectl get pods -n observability --no-headers | wc -l) ]]; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    
    if [[ $ELAPSED_TIME -ge $TIMEOUT ]]; then
        echo "Timeout reached: Not all pods in the observability namespace are ready."
        exit 1
    fi
    
    echo "Waiting for all pods in the observability namespace to be ready..."
    sleep 5
done

ENVOY_PORT=$(docker ps --format='{{json .}}' -f=name=kindccm | jq .Ports | grep -oP '0\.0\.0\.0:\K\d+(?=->80/tcp)')

echo Grafana is available at http://localhost:"$ENVOY_PORT"