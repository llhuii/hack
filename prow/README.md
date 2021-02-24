# prow
simple scripts for installing prow in a kind k8s cluster.

1. Follow [the official doc](https://github.com/kubernetes/test-infra/blob/master/prow/getting_started_deploy.md#update-the-sample-manifest) to update the sample manifest. I use [the s3 sample manifest](https://github.com/kubernetes/test-infra/blob/master/config/prow/cluster/starter-s3.yaml) as template, see [my already updated yaml](./starter-s3.yaml).
1. After done, rename your template as `starter-s3.yaml`
1. Just run the start script:
    ```sh
    bash start.sh
    ```
    the end output would be:
    ```text
    deployment.apps/minio created
    service/minio created
    pod/hook-77b98499b9-f2tsv condition met
    forwarding 192.168.0.13:30000 to 172.18.0.2:30271
    ```
1. test the hook to get OK status code:
    ```sh
    curl -i 192.168.0.13:30000
    ```
