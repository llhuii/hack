
This directory tests the `default` Service Account for Pod scheduled into edge nodes managed by kubeedge.
## Test `default` Service Account.

### First time
1. run the test script:
  ```bash
  MASTER_IP=sedna-mini-control-plane NS=llh bash k8s-in-cluster-config.sh
  ```
  this script will create a namespace for testing:
  - rolebinding for viewing k8s resource permission.
  - A job named access-api testing the default token,  it will be scheduled into edge nodes.

1. Get the pod's nodeName
  ```bash
  kubectl get -n llh pod -o wide
  ```
1. Open another terminal tab, login the edge node, see the pod log using `docker logs <pod_container_id>`, you will see:
  ```txt
  I0913 07:52:15.448795       1 k8s-in-cluster.go:51] Get 1 pods successfully
  ```

### Second time
Delete the `access-api` job by `kubectl -n llh delete job access-api`, do the commands in the first time again.

But in the logs command, you will see this instead:
  ```txt
  E0913 09:16:49.148799       1 k8s-in-cluster.go:49] Failed to get pods: Unauthorized
  ```

## Clean it
```bash
NS=llh bash k8s-in-cluster-config.sh clean
```
