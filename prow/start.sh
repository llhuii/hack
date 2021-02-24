#!/bin/bash

set -e

source source.sh

create_kind_cluster() {
  kind create cluster --name $CLUSTER_NAME --wait 90s
}

create_prow() {
  kubectl create -f starter-s3.yaml
}

wait_hook() {
  while ! kubectl -n prow get pod |grep -q hook; do
    sleep 1
  done
  kubectl wait -n prow --for=condition=Ready -l app=hook pod --timeout=90s
}

create_kind_cluster

create_prow

wait_hook

HOST_IP=$(get_host_ip) MASTER_IP=$(get_master_ip)
. forward-proxy.sh

add_rule 
