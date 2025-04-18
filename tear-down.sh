#! /bin/bash

kind delete cluster --name otel-hello-world

docker stop cloud-controller-manager