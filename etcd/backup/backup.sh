#!/bin/bash
# A script to backup etcd of a Kubernetes into OSS using etcd-operator-backup tool.
# Required tools:
# 1. kubectl
#
# Influential env vars:
#
# MASTER_URL      | required | Master url
# CLUSTER_ID      | required | Cluster ID
# NS              | optional | The namespace to be apply, default kube-system
#
# OSS_REGION      | required | OSS region
# OSS_AK          | required | OSS access key
# OSS_SK          | required | OSS secret key
# OSS_PATH_PREFIX | optional | OSS path prefix, default ${oss_region}-etcd-back/etcd-backup/
#
# BACKUP_INTERVAL_IN_MIN | optional | The back interval in minute, default 60
# MAX_BACKUPS            | optional | The max backup to keep, default 3
#
# ETCD_OPERATOR_USER     | optional | The user name to pull etcd operator image, default etcd_cloud
# ETCD_OPERATOR_PASSWD   | required | The password to pull etcd operator image
# ETCD_OPERATOR_VERSION  | optional | The etcd operator image version, default v1.8.6_de86365b2e1


set -o errexit
set -o nounset

# 准备环境配置
master_url=${MASTER_URL}
cluster_id=${CLUSTER_ID}


# oss config
oss_region=$OSS_REGION
oss_ak=$OSS_AK
oss_sk=$OSS_SK

oss_path_prefix=${OSS_PATH_PREFIX:-${oss_region}-etcd-bak/etcd-backup}

oss_path=${oss_path_prefix%/}/${cluster_id}/etcd.backup

oss_endpoint=oss-${oss_region}-internal.aliyuncs.com

: ${NS:=kube-system}

etcd_operator_image=${ETCD_OPERATOR_IMAGE:-registry-vpc.${oss_region}.aliyuncs.com/alpha_etcd/etcd-operator}
etcd_operator_version=${ETCD_OPERATOR_VERSION:-v1.8.6_de86365b2e1}
etcd_operator_user=${ETCD_OPERATOR_USER:-etcd_cloud}

etcd_operator_passwd=${ETCD_OPERATOR_PASSWD}

backup_interval_in_second=$((${BACKUP_INTERVAL_IN_MIN:-60}*60))
max_backups=${MAX_BACKUPS:-3}

TIMEOUT=90


### 2. 获取etcd client连接信息

function kubectl() {
  [ -z "$master_url" ] && {
    command kubectl "$@"
    return
  }

  command kubectl -s "$master_url" "$@"
}

function enable_hostnetwork() {
  echo true
}

function apply_rbac() {

  service_account=etcd-backup-operator

  kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: etcd-backup-operator
  namespace: $NS
---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: etcd-backup-operator
rules:
- apiGroups:
  - etcd.alibabacloud.com
  resources:
  - etcdbackups
  verbs:
  - "*"

- apiGroups:
  - apiextensions.k8s.io
  resources:
  - customresourcedefinitions
  verbs:
  - "*"

- apiGroups:
  - ""
  resources:
  - endpoints
  - events
  verbs:
  - "*"

- apiGroups:
    - ""
  resources:
    - secrets
    - configmaps
  verbs:
    - "*"

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: etcd-backup-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: etcd-backup-operator
subjects:
- kind: ServiceAccount
  name: $service_account
  namespace: $NS

EOF
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


function setup_etcd_connection() {
  # setup etcd connection config
  local secret_name=etcd-client-tls-secret
  if [ -z "${IS_RKE_CLUSTER:-}" ] ; then
    apiserver_commands=($(kubectl get -n kube-system pod -l component=kube-apiserver -o jsonpath='{.items[0].spec.containers[0].command[*]}'))

    etcd_endpoints=$(get_apiserver_option etcd-servers)

    etcd_cafile=$(get_apiserver_option etcd-cafile)
    etcd_certfile=$(get_apiserver_option etcd-certfile)
    etcd_keyfile=$(get_apiserver_option etcd-keyfile)
  else
  
    etcd_endpoints=$(kubectl get node -l node-role.kubernetes.io/master -o wide | awk '$3!~/worker/&&NR>1&&$0="https://"$6":2379"' | tr '\n' , | sed 's/,$//')
    if [ -z "$etcd_endpoints" ] ; then
      etcd_endpoints=
    fi

    # TOFIXME: these are fixed on rke
    etcd_cafile=/etc/kubernetes/ssl/kube-ca.pem
    etcd_certfile=/etc/kubernetes/ssl/kube-node.pem
    etcd_keyfile=/etc/kubernetes/ssl/kube-node-key.pem
  fi

  etcd_cert_dir=$(dirname $etcd_cafile)

  kubectl -n $NS get secret $secret_name --ignore-not-found | grep $secret_name -q && return

  { 
    local job_name=gen-etcd-tls-secret 
    kubectl -n $NS delete job $job_name --ignore-not-found

    kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $job_name
  namespace: $NS
spec:
  completions: 1
  template:
    metadata:
      name: $job_name
    spec:
      hostNetwork: $(enable_hostnetwork)
      securityContext:
        runAsUser: 0
      serviceAccount:  $service_account

      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role.kubernetes.io/master
                operator: Exists

      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
          operator: Exists
        - effect: NoSchedule
          key: node.kubernetes.io/network-unavailable
          operator: Exists
        - effect: NoSchedule
          key: node-role.kubernetes.io/controlplane
          operator: Exists
        - effect: NoExecute # for polarx
          key: node-role.kubernetes.io/etcd
          operator: Exists

      imagePullSecrets:
        - name: docker-image-secret

      containers:
      - name: gen
        image: ${KUBECTL_IMAGE:-bitnami/kubectl:1.18}
        args:
        - create
        - secret
        - -n
        - $NS
        - generic
        - $secret_name
        - --from-file=ca.pem=$etcd_cafile
        - --from-file=key.pem=$etcd_keyfile
        - --from-file=cert.pem=$etcd_certfile
        volumeMounts:
        - mountPath: $etcd_cert_dir
          name: etcd-certs
          readOnly: true
      volumes:
      - hostPath:
          path: $etcd_cert_dir
          type: Directory
        name: etcd-certs

      restartPolicy: OnFailure

EOF

    kubectl -n $NS wait --timeout=${TIMEOUT}s --for=condition=complete job/$job_name
    # clean job once done
    kubectl -n $NS delete job/$job_name
  }

}


function deploy_etcd_backup_operator() {
  # 部署etcd backup operator

  create_pull_secret_args=(
    -n "$NS"
    create secret docker-registry regetcd
    --docker-username "$etcd_operator_user"
    --docker-password "$etcd_operator_passwd"
    --docker-server=$(echo "$etcd_operator_image" | cut -d/ -f1)
  )
  kubectl -n $NS get secret regetcd --ignore-not-found | grep -q regetcd || kubectl "${create_pull_secret_args[@]}"

  kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: etcd-backup-operator
  namespace: $NS
spec:
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  selector:
    matchLabels:
      app: etcd-backup-operator
  replicas: 1
  template:
    metadata:
      labels:
        app: etcd-backup-operator
    spec:
      serviceAccount: $service_account
      hostNetwork: $(enable_hostnetwork)
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role.kubernetes.io/master
                operator: Exists

      imagePullSecrets:
        - name: regetcd

      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
          operator: Exists
        - effect: NoSchedule
          key: node.kubernetes.io/network-unavailable
          operator: Exists

        - effect: NoSchedule
          key: node-role.kubernetes.io/controlplane
          operator: Exists
        - effect: NoExecute   # for polarx
          key: node-role.kubernetes.io/etcd
          operator: Exists

      containers:
      - name: etcd-backup-operator
        image: ${etcd_operator_image}:$etcd_operator_version
        command:
        - etcd-backup-operator
        - cluster-wide=false

        resources:
          limits:
            cpu: 2
            memory: 512Mi
          requests:
            cpu: 200m
            memory: 128Mi
        env:
        - name: MY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: MY_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
EOF

  # wait etcd backup operator to be ready
  kubectl -n $NS wait --timeout=${TIMEOUT}s deployment/etcd-backup-operator --for condition=available

  for((i=0;i<60;i++)); do
    kubectl get crd etcdbackups.etcd.alibabacloud.com 2>/dev/null || {
      sleep 1
      continue
    }
    return
  done
  echo Timeout to wait etcdbackup crd to be created >&2
  return 1
}

function apply_backup_cr(){

  # 创建oss secret
  local secret_name=oss-secret
  kubectl -n $NS get secret $secret_name --ignore-not-found | grep -q "$secret_name" || {
    kubectl -n $NS create secret generic $secret_name --from-literal=accessKeyID=$oss_ak --from-literal=accessKeySecret=$oss_sk
  }

  # 创建backup CR
  #
  for i in 0 1 2; do 
  kubectl apply -f - <<EOF && break

apiVersion: "etcd.alibabacloud.com/v1beta2"
kind: "EtcdBackup"
metadata:
  name: backup
  namespace: $NS
spec:
  clientTLSSecret: etcd-client-tls-secret
  etcdEndpoints: [ $etcd_endpoints ]
  storageType: OSS
  backupPolicy:
    backupIntervalInSecond: ${backup_interval_in_second}
    timeoutInSecond: 30
    maxBackups: ${max_backups:-3}
  oss:
    # The format of "path" must be: "<s3-bucket-name>/<path-to-backup-file>"
    path: ${oss_path}
    ossSecret: oss-secret
    endpoint: $oss_endpoint
EOF
echo  wait crd to be complete
sleep 2
done
}

main() {

  apply_rbac
  setup_etcd_connection
  deploy_etcd_backup_operator
  apply_backup_cr
}

# check apiserver
kubectl get node -l node-role.kubernetes.io/master |grep -q NAME

way=main
if [ -z "${FORCE_UPDATE:-}" ]; then
  ! kubectl get -n $NS etcdbackups backup >/dev/null 2>&1 || way=true
fi

$way
