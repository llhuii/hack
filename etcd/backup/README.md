本目录提供以下脚本功能：
1. backup.sh: 一键将etcd-operator backup能力部署到一个K8S集群。
2. etcdctl.sh: etcdctl相关命令，当前集成快照能力，可用于验证与调试。

### 1. 一键将etcd-operator backup能力部署到K8S集群
前提条件：
1. kubectl 命令且能访问K8S

环境配置选项，参见[样例脚本](./backup-example.sh):

| Env Variable | 是否必须 | 描述|
| --- |  --- | --- |
｜ MASTER_URL      | required | Master url
｜ CLUSTER_ID      | required | Cluster ID
｜ NS              | optional | The namespace to be apply, default kube-system
｜ OSS_REGION      | required | OSS region
｜ OSS_AK          | required | OSS access key
｜ OSS_SK          | required | OSS secret key
｜ OSS_PATH_PREFIX | optional | OSS path prefix, default ${oss_region}-etcd-back/etcd-backup/
｜ BACKUP_INTERVAL_IN_MIN | optional | The back interval in minute, default 60
｜ MAX_BACKUPS            | optional | The max backup to keep, default 3
｜ ETCD_OPERATOR_USER     | optional | The user name to pull etcd operator image, default etcd_cloud
｜ ETCD_OPERATOR_PASSWD   | required | The password to pull etcd operator image
｜ ETCD_OPERATOR_VERSION  | optional | The etcd operator image version, default v1.8.6_de86365b2e1

注：
1. 如果是通过网关访问K8S，需在这下载[kubectl](https://liulinghui-chengjin.oss-cn-zhangjiakou.aliyuncs.com/kubectl-user-agent).
2. 如果期望通过KUBECONFIG访问K8S，可置MASTER_URL为空.

#### 2. 将etcd快照保存到本地

前提条件：
1. 已登陆到集群的worker节点
2. kubeconfig 能exec到kube-apiserver

快照到本地的命令：
```sh
(
source etcdctl.sh
save_snapshot
)
```