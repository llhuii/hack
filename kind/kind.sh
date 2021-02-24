set_kind_cluster() {
  local cluster_name="${1:-kind}"
  if kind get clusters | grep -q -F -x "$cluster_name"; then
    kind get kubeconfig --name "$cluster_name" > /tmp/.${cluster_name}.config
    export KUBECONFIG=/tmp/.${cluster_name}.config
  else echo "unknow cluster name '$cluster_name'";
  fi
}

kind_exec() {
  name=${1:-kind}
  docker exec -it --detach-keys=ctrl-@ ${name}-control-plane bash
}
