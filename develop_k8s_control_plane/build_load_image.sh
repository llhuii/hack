#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

: ${KUBE_ROOT:=$HOME/kubernetes}
: ${KIND_NAME:=kind}


bins=(
kube-controller-manager
kube-apiserver
)

DEFAULT_WHAT="${bins[@]}"

: ${WHAT:="$DEFAULT_WHAT"}


get_master() {
  kubectl get node -l node-role.kubernetes.io/master | awk 'NF=NR==2'
}


load_image() {
  bin=${1}
  #docker save $image | docker exec -i $(get_master) ctr -n k8s.io image import -
  kind load docker-image --name $KIND_NAME --nodes $(get_master) $image
}


make_image() {
  bin=${1}
  image=$bin:test
  ( 
    cd $KUBE_ROOT
    make KUBE_BUILD_CONFORMANCE=n WHAT=cmd/$bin
    source build/common.sh
    cd _output/bin

    cat > Dockerfile <<EOF
# https://code.k8s.io/build/common.sh 
# FROM k8s.gcr.io/build-image/go-runner:v2.3.1-go1.17.1-bullseye.0
FROM $KUBE_GORUNNER_IMAGE
COPY $bin /usr/local/bin/$bin

EOF
    docker build -t $image .
  )
}

load_images() {
  for bin; do
    bin=kube-${bin/kube-/}
    time make_image $bin
    load_image $bin
  done
}

what=(${WHAT//,/ })

load_images "${what[@]}"
