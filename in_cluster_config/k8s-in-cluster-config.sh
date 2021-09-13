# env KUBERNETES_SERVICE_{HOST,PORT} should be set under pods,
# but service env keys are unsupportted in kubeedge.
: ${MASTER_IP:=sedna-mini-control-plane}
: ${MASTER_PORT:=6443}


: ${NS:=t16}

do_clean() {
  kubectl delete ns $NS
}

do_apply() {
  action=apply

  kubectl $action -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NS
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-view
  namespace: $NS
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: default
  namespace: $NS
---
apiVersion: batch/v1
kind: Job
metadata:
  name: access-api
  namespace: $NS
spec:
  template:
    spec:
      nodeSelector:
        node-role.kubernetes.io/edge: ""
      restartPolicy: OnFailure
      hostNetwork: true
      containers:
      - name: access-k8s-api
        image: llhuii/k8s-in-cluster-config:v0.1
        imagePullPolicy: Always
        env:
          - name: KUBERNETES_SERVICE_HOST
            value: "$MASTER_IP"
          - name: KUBERNETES_SERVICE_PORT
            value: "$MASTER_PORT"
EOF
}

action=${1:-apply}

case "$action" in
  apply|create) do_apply;;
  delete|clean) do_clean;;
  *) echo "Unknow action $action" >&2; exit 2;;
esac

