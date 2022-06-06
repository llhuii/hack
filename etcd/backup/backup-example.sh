#!/bin/bash

CLUSTER_ID=c5a6ba264ccdd430a9e73cebb3d2d2f47
MASTER_URL=${CLUSTER_ID}-ackk8s-atp-3909.igw.rdstest.tbsite.net
OSS_REGION=cn-zhangjiakou
OSS_AK=xxxx
OSS_SK=xxxx
OSS_PATH_PREFIX={bucket-name}/etcd-backup-dev

ETCD_OPERATOR_USER=etcd_cloud
ETCD_OPERATOR_PASSWD=xxxx

BACKUP_INTERVAL_IN_MIN=120
MAX_BACKUPS=4

# Since here master_url is from gateway, and current gateway limit POST request of ACK_K8S,
# we need to set USER_AGENT of connection to CommonProvider or RM-OPERATOR.
#
# But offical kubectl don't support this, I have created kubectl on:
#   https://liulinghui-chengjin.oss-cn-zhangjiakou.aliyuncs.com/kubectl-user-agent
#
# Download it: curl -o kubectl https://liulinghui-chengjin.oss-cn-zhangjiakou.aliyuncs.com/kubectl-user-agent

export KUBE_USER_AGENT=rm-operator

source backup.sh
