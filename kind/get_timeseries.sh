#!/bin/bash

get_creation_time () {
grep creation | awk '!/null/&&$0=$2'
}
get_node_creation() {
  echo -n "$1 creation: "
  kubectl get node $1 -o yaml | get_creation_time
}

get_node_ready() {
  echo -n "$1 ready: "
  kubectl get node $1 -o jsonpath='{.status.conditions[?(@.reason=="KubeletReady")].lastTransitionTime}'
  echo 
}

get_deploy_creation() {
  echo -n "deploy $1:"
  kubectl get deploy -n kube-system $1 -o yaml |get_creation_time
  get_pod_status $1
}

get_ds_creation() {
  echo -n "ds $1:"
  kubectl get ds -n kube-system $1 -o yaml |get_creation_time
  get_pod_status $1
}

get_pod_full_name() {
  kubectl get pod -n kube-system | grep "$1" | awk NF=1
}

get_pod_status() {
  for pod in $(get_pod_full_name $1); do
  
    echo "pod $pod: "
    echo -ne "\t creation: "; kubectl get pod -n kube-system $pod -o yaml |get_creation_time
    for s in Ready PodScheduled; do
      echo -en "\t $s: "
      _get_pod_specified_status $pod $s
    done
  done
}

_get_pod_specified_status() {
  pod=$1 status=$2

  kubectl get pod -n kube-system $pod -o jsonpath='{.status.conditions[?(@.type=="'$status'")].lastTransitionTime}'
  echo 
}

get_node_time() {
  name=$(kubectl get node | awk '/control/&&NF=1')
  get_node_creation $name
  get_node_ready $name
}

show() {
get_node_time
get_ds_creation kindnet
get_ds_creation  kube-proxy
get_deploy_creation  coredns
}
