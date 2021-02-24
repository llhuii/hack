#!/bin/bash
set -e

. source.sh

clean_prow() {
  kind delete cluster --name $CLUSTER_NAME
}

HOST_IP=$(get_host_ip)
MASTER_IP=$(get_master_ip)

. forward-proxy.sh

delete_rule

clean_prow
