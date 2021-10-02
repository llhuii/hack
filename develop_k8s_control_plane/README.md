This directory is used to develop the upstream [Kubernetes code](https://code.k8s.io)

Suppose you have:
- A KinD Kubernetes master named `kind`
- Kubernetes source at $HOME/kubernetes

# build and load controller-manager
```bash
KUBE_ROOT=$HOME/kubernetes KIND_NAME=kind WHAT=controller-manager build_load_image.sh 
```

## edit controller-manager manifest

login the control plane:
```bash
docker exec -it --detach-keys=ctrl-@ kind-control-plane bash

```

edit the controller-manager image:
```bash
cd /etc/kubernetes/manifests
what=kube-controller-manager
sed -i "s/image: .*/image: $what:test  # &/" $what.yaml
```



# build and load apiserver

```bash
KUBE_ROOT=$HOME/kubernetes KIND_NAME=kind WHAT=apiserver build_load_image.sh 
```

login the control plane:
```bash
docker exec -it --detach-keys=ctrl-@ kind-control-plane bash

```

edit the apiserver image:
```bash
cd /etc/kubernetes/manifests
what=kube-apiserver
sed -i "s/image: .*/image: $what:test  # &/" $what.yaml
```
