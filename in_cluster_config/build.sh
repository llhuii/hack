#!/bin/bash
tag=llhuii/k8s-in-cluster-config:v0.1
docker build -t $tag . && docker push $tag
