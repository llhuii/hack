export PATH=/root/go/src/github.com/kubernetes-sigs/kind/bin:$PATH
#export PATH=/tmp/:$PATH
name=cni-ph
name=o
time kind delete cluster --name $name
#
time kind create cluster --name $name  -v7
kubectl cluster-info --context kind-$name
#time kubectl wait --for=condition=Ready node/$name-control-plane --timeout=90s

date
kubectl get node -o yaml > node1.log
while ! time kubectl wait --for=condition=ready pods --namespace=kube-system -l k8s-app=kube-dns; do date; sleep 1; done
date
sleep 10
kubectl get node -o yaml > node_after_10.log

#cat /tmp/10-kindnet.conflist | docker exec -i test-control-plane  tee  /etc/cni/net.d/10-kindnet.conflist;

: echo '

{
	"cniVersion": "0.3.0",
	"name": "kindnet0",
	"plugins": [
     { "type": "portmap" }
	]
}
' #| docker exec -i test-control-plane  tee  /etc/cni/kinnet.conflist;
#' | docker exec -i test-control-plane  tee  /etc/cni/net.d/kindnet.conflist;
