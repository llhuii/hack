package main

import (
	"context"
	"os"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/klog/v2"
)

func main() {
	envAndDefault := []string{
		"KUBERNETES_SERVICE_HOST", "127.0.0.1",
		"KUBERNETES_SERVICE_PORT", "443",
	}
	for i := 0; i < len(envAndDefault); i += 2 {
		env := envAndDefault[i]
		if os.Getenv(env) == "" {
			val := envAndDefault[i+1]
			klog.Warningf("%s unset use default: %s", env, val)
			os.Setenv(env, val)
		}
	}

	config, err := rest.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}
	/*
		nodes, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
		if err != nil {
			klog.Errorf("Failed to get nodes: %v", err)
		} else {
			klog.Infof("Get %d nodes successfully", len(nodes.Items))
		}
	*/

	content, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/namespace")
	ns := string(content)
	pods, err := clientset.CoreV1().Pods(ns).List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		klog.Errorf("Failed to get pods: %v", err)
	} else {
		klog.Infof("Get %d pods successfully", len(pods.Items))
	}
	_ = pods
}
