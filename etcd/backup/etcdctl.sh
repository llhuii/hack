#!/bin/bash
set -o errexit
set -o nounset

mkdir -p $HOME/etcd; cd $HOME/etcd

export PATH="$PATH:$PWD"

! [ -f ".config" ] || export KUBECONFIG=$PWD/.config

function ensure_etcdctl() {
  etcdctl version >/dev/null 2>&1 || {
    curl -O https://monkeyking-asi.oss-cn-zhangjiakou.aliyuncs.com/acr/etcdctl
    chmod +x etcdctl
    # check again
    etcdctl version >/dev/null 2>&1
  }
}

function get_apiserver_option() {
  local option=$1 o k v
  for o in "${apiserver_commands[@]}"; do
    k=${o/=*}
    v=${o/*=}
    if [ "$k" = "--$option" ]; then
      echo "$v"
      return
    fi
  done
  return 2
}

function save_etcd_certs() {
  local remote f

  for remote in "$@"; do
    f=$(basename $remote)
    {
      # try to exec api server, otherwise local file system
      timeout 5 kubectl -n kube-system exec $apiserver_name -- cat $remote || cat $remote
    } > $f
  done

}

function setup_etcd_certs() {

  # setup etcd connection config
  apiserver_name=$(kubectl -n kube-system get pod -l component=kube-apiserver |grep Running | awk NF=1 | head -n1)
  apiserver_commands=($(kubectl get -n kube-system pod "$apiserver_name" -o jsonpath='{.spec.containers[0].command[*]}'))

  etcd_endpoints=$(get_apiserver_option etcd-servers)

  etcd_cafile=$(get_apiserver_option etcd-cafile)
  etcd_certfile=$(get_apiserver_option etcd-certfile)
  etcd_keyfile=$(get_apiserver_option etcd-keyfile)

  (($(ls etcd/*.pem |wc -l) >= 3)) || save_etcd_certs $etcd_cafile $etcd_certfile $etcd_keyfile
  etcd_cafile=./$(basename $etcd_cafile)
  etcd_certfile=./$(basename $etcd_certfile)
  etcd_keyfile=./$(basename $etcd_keyfile)

}

function get_snap_endpoint() {
  [ -z "$SNAP_ENDPOINT" ] || {
    # add default proto and port

    echo "$SNAP_ENDPOINT" | awk '
    !/^https?:/{$0="https://"$0}
    !/:[0-9]+$/{$0=$0":2379"}
    1
    '
    return
  }

  local c=$(echo $etcd_endpoints | tr ',' '\n' | grep -c http)
  local idx=$(($RANDOM%c+1))
  echo $etcd_endpoints | tr ',' '\n' | awk NR==$idx
}

function save_snapshot() {

  export ETCDCTL_API=3

  etcdctl --endpoints $(get_snap_endpoint) --cacert=$etcd_cafile --cert=$etcd_certfile --key=$etcd_keyfile snapshot save etcd.db
}

ensure_etcdctl
setup_etcd_certs
echo "etcd commands options:
  cd $PWD; etcdctl --endpoints $etcd_endpoints --cacert=$etcd_cafile --cert=$etcd_certfile --key=$etcd_keyfile
"
