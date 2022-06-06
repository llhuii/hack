#!/bin/bash
# 恢复etcd通过设置环境变量ETCD_DATA_DL_URL
# usage: 
#   ETCD_DATA_DL_URL='https://back.oss-cn-zhangjiakou.aliyuncs.com/etcd-backup-dev/c5/etcd.backup_v147875484_2022-04-08-04' bash -x restore.sh

# 原理：获取etcd启动选项来构造etcd节点配置，目录等信息
#
# 支持systemctl/docker管理的etcd（默认通过名为etcd的来获取，可以通过ETCD_MANAGED_NAME设置)

set -o errexit
set -o nounset

restore_dir=${HOME:-/tmp}/etcd-restore

mkdir -p "$restore_dir"

cd "$restore_dir"

export PATH="$PATH:$PWD"

managed_name=${ETCD_MANAGED_NAME:-etcd}


function ensure_etcdctl() {
  etcdctl version >/dev/null 2>&1 || {
    curl -O https://monkeyking-asi.oss-cn-zhangjiakou.aliyuncs.com/acr/etcdctl
    chmod +x etcdctl
    # check again
    etcdctl version >/dev/null 2>&1
  }
}

function download_backup_from_oss() {
  code=$(curl -o "${2}" -L -s "$1" -w "%{http_code}")
  if ((code >= 300)); then
    head "${2}" >&2
    return 2
  fi
}

function get_etcd_manager() {
  systemctl cat $managed_name >/dev/null && echo systemd || echo docker
}

function systemd_stop_etcd() {
  systemctl stop $managed_name
}

function systemd_start_etcd() {
  systemctl start $managed_name
}

function systemd_get_options() {
  # systemctl show example:
  # ExecStart={ path=/usr/bin/etcd ; argv[]=/usr/bin/etcd --election-timeout=3000 ... ; }
  systemctl show -p ExecStart $managed_name | sed -e 's/.*argv\[\]=//; s/ ;.*//'
}

function systemd_get_mount_path() {
  echo "$@"
}

function docker_stop_etcd() {
  docker stop $managed_name
}

function docker_start_etcd() {
  docker start $managed_name
}

function docker_get_options() {
  docker inspect $managed_name --format='{{range $o := .Args}}{{$o}} {{end}}'
}

function docker_get_mount_path() {
  local path=${1%/}  # strip trailing /
      docker inspect $managed_name --format='{{range .Mounts}}{{.Source}} {{.Destination}}
        {{end}}' | while read source dst _extra; do
        len=${#dst}
        if [[ ${path::len} == "$dst" ]]; then
          echo ${source}${path: len}
          break
          fi
  done
}


function prepare_etcd_config() {
etcd_manager=$(get_etcd_manager)

get_etcd_config_from_os

# name=192.168.19.60-name-2
# initial_clusters=192.168.9.7-name-1=https://192.168.9.7:2380,192.168.19.60-name-2=https://192.168.19.60:2380,192.168.31.174-name-3=https://192.168.31.174:2380

current_peer_url=$(echo "$initial_clusters" | tr , '\n' | sed "s/^$name=//;/=/d")
}

function prepare_restore_file() {

restore_file="$restore_dir/etcd-oss.db"

if [[ "${ETCD_DATA_DL_URL:-}" == http* ]]; then
  download_backup_from_oss "$ETCD_DATA_DL_URL" "$restore_file"
else  # local file
  restore_file=${ETCD_DATA_DL_URL:-}
fi

  [ -f "$restore_file" ] || {
    echo "Can't prepare restore file" >&2
    echo "Please setup the right ETCD_DATA_DL_URL: $ETCD_DATA_DL_URL" >&2
    exit 2
  }

}


function get_etcd_option() {
  local option=$1 o k v i=0
  for ((i = 0; i < ${#etcd_options[@]}; i++)); do
    o=${etcd_options[i]}

    if echo "$o" | grep -q =; then
      k=${o/=*/}
      v=${o/$k=/}
    else
      k=${o}
      v=${etcd_options[i + 1]}
    fi

    if [ "$k" = "--$option" ]; then

      echo "$v"
      return
    fi
  done

  return 2
}

function get_etcd_config_from_os() {

  # try to search existing etcd pid
  # only systemd for etcd is supported
  # todo for docker
  pid=$(systemctl show --property MainPID $managed_name | cut -f2 -d= || echo 0)

  if ! [ -d "/proc/$pid" ]; then
    # /usr/bin/etcd /usr/loca/bin/etcd
    pid=$(pgrep -f /bin/etcd || echo 0)
  fi

  # try to get from current etcd process
  if [ -e "/proc/${pid}/cmdline" ]; then
    etcd_options=(
        $(tr '\0' ' ' < "/proc/${pid}/cmdline")
    )
  else
    etcd_options=(
       $(${etcd_manager}_get_options)
    )
  fi

  name=$(get_etcd_option name)
  initial_clusters=$(get_etcd_option initial-cluster)
  data_dir=$(get_etcd_option data-dir)

  # not absolute path
  # ack cluster: --data-dir=data.etcd
  if ! [[ "$data_dir" = /* ]]; then
    data_dir=$(cd /proc/${pid}/cwd 2>/dev/null || cd $(systemctl show -p WorkingDirectory etcd | cut -f2 -d= ); realpath "$data_dir")
  fi

  data_dir=$(${etcd_manager}_get_mount_path $data_dir)

}


function do_restore() {
  snapshot_dir=${name}.etcd
  # 1. restore to $snapshot_dir
  rm -rf "$snapshot_dir"
  ETCDCTL_API=3 etcdctl snapshot restore "$restore_file" --name="${name}" --initial-cluster="$initial_clusters" --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls "$current_peer_url" --skip-hash-check=true


  # 2. try to stop etcd
  "${etcd_manager}_stop_etcd" || true

  # 3. backup origin if any
  origin_path="origin"
  mkdir -p "$origin_path"

  sudo mv --backup=numbered "${data_dir}/member" "$origin_path" || true

  # 4. keep user:group ownership, and restore, default try 'etcd' user
  ug=$(stat -c "%U:%G" "${data_dir}" || echo etcd:etcd)

  # if not exists
  sudo mkdir -p "${data_dir}"

  sudo chown -R $ug "${snapshot_dir}/member" "${data_dir}" 2>/dev/null || true

  sudo cp -a "${snapshot_dir}"/member "${data_dir}"/

  # 5. left start-etcd action manually when all etcd restore are done
}

ensure_etcdctl
prepare_restore_file
prepare_etcd_config

do_restore
