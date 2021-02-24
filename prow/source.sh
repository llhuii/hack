CLUSTER_NAME=${CLUSTER_NAME:-prow}

check_and_install_kind() {
  type kind &>/dev/null || {
    curl -Lo /usr/local/bin/kind "https://kind.sigs.k8s.io/dl/v0.10.0/kind-$(uname)-amd64"
    chmod +x /usr/local/bin/kind
  }
}

check_tools() {
  type kubectl >/dev/null
  type docker >/dev/null
}

export_kind_kubeconfig() {

  export KUBECONFIG=${CLUSTER_NAME}-kube-config

  kind get kubeconfig --name "$CLUSTER_NAME" > ${KUBECONFIG}
}

get_host_ip() {
  # find the first ens/eth network interface
  local addr=$(
    # the output of ip:
    # "2: eth0    inet 192.168.0.143/24 brd"
    ip -4 -o addr | 
      awk 'sub(/^ens|^eth/, e, $2){print $2,$4}' |
      sort -n | awk 'sub("/.*",e){print $2; exit}' | head -n1
  )
  echo ${addr:-"127.0.0.1"}
}

get_master_ip() {
  kubectl get node ${CLUSTER_NAME}-control-plane -o jsonpath='{.status.addresses[?(.type=="InternalIP")].address}'
}

check_tools
check_and_install_kind
