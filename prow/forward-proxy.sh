#!/bin/bash

INGRESS_PORT=${INGRESS_PORT:-30000}

set -e
set -u

kind_network_id=$(docker network ls | awk '$2=="kind"&&NF=1')

nat_rule() {
  local p=${1} d=${2:-$1}
  echo DOCKER -d ${HOST_IP} ! -i br-${kind_network_id} -p tcp -m tcp --dport $p  -j DNAT --to-destination $MASTER_IP:$d
}

forw_rule() {
  local p=${1}
  echo DOCKER -d $MASTER_IP/32 ! -i br-${kind_network_id} -o br-${kind_network_id} -p tcp -m tcp --dport $p -j ACCEPT
}

add_rule(){
  set $INGRESS_PORT $(get_hook_port)
  echo forwarding $HOST_IP:$1 to $MASTER_IP:$2
  sudo iptables -t nat -A $(nat_rule $1 $2) || true
  sudo iptables -A $(forw_rule $2) || true
}

delete_rule() {
  set $INGRESS_PORT $(get_hook_port)
  sudo iptables -t nat -D $(nat_rule $1 $2) || true
  sudo iptables -D $(forw_rule $2) || true
}

get_hook_port() {
  kubectl get svc -n prow |
  grep -i nodeport |
  grep hook|
  awk '($0=$5)&&sub(/.*:/,e)sub("/.*",e)'
}
