#!/bin/bash

CLUSTER_ID=etcd-drill-ack
MASTER_URL= #${CLUSTER_ID}-ackk8s-atp-3909.igw.rdstest.tbsite.net

#MASTER_URL=${CLUSTER_ID}-ackk8s-atp-3909.igw.rdstest.tbsite.net

OSS_REGION=cn-zhangjiakou
OSS_AK=xxxx
OSS_SK=xxxx

OSS_PATH_PREFIX=liulinghui-chengjin/etcd-drill

docker_username=xxx
docker_pwd=xxx

kubectl create secret docker-registry docker-image-secret --docker-server=registry-vpc.$OSS_REGION.aliyuncs.com --docker-username=$docker_username --docker-password=$docker_pwd -n kube-system || true

ETCD_OPERATOR_USER=$docker_username
ETCD_OPERATOR_PASSWD=$docker_pwd

BACKUP_INTERVAL_IN_MIN=20
MAX_BACKUPS=5

export KUBE_USER_AGENT=rm-operator

KUBECTL_IMAGE=registry-vpc.${OSS_REGION}.aliyuncs.com/apsaradb_on_ecs/kubectl:v1.18.8
ETCD_OPERATOR_IMAGE=registry-vpc.${OSS_REGION}.aliyuncs.com/apsaradb_on_ecs/etcd-backup-operator
ETCD_OPERATOR_VERSION=v1.8.9_ab4ce048a0c

source ../backup.sh
