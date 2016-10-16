#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

apt-get install bridge-utils

echo "Copying kubernetes service configuration files"
mkdir /etc/kubernetes
mkdir /etc/kubernetes/flannel
mkdir /etc/kubernetes/manifests-multi
mkdir /etc/kubernetes/addons

cp -f ./rootfs/etc/kubernetes/k8s.conf /etc/kubernetes/k8s.conf
cp -f ./rootfs/lib/systemd/system/k8s-docker-bootstrap.service /lib/systemd/system/k8s-docker-bootstrap.service
cp -f ./rootfs/lib/systemd/system/k8s-docker-bootstrap.socket /lib/systemd/system/k8s-docker-bootstrap.socket
cp -f ./rootfs/lib/systemd/system/k8s-etcd.service /lib/systemd/system/k8s-etcd.service
cp -f ./rootfs/lib/systemd/system/k8s-flannel.service /lib/systemd/system/k8s-flannel.service
cp -f ./rootfs/lib/systemd/system/k8s-docker.service /lib/systemd/system/k8s-docker.service
cp -f ./rootfs/lib/systemd/system/k8s-docker.socket /lib/systemd/system/k8s-docker.socket
cp -f ./rootfs/lib/systemd/system/k8s-master.service /lib/systemd/system/k8s-master.service

cp -f ./conf/kube-api-server.yaml /etc/kubernetes/manifests-multi
cp -f ./conf/kube-manager.yaml /etc/kubernetes/manifests-multi
cp -f ./conf/kube-proxy.yaml /etc/kubernetes/manifests-multi
cp -f ./conf/kube-scheduler.yaml /etc/kubernetes/manifests-multi
cp -f ./addons/kube-dns-rc.yaml /etc/kubernetes/addons
cp -f ./addons/kube-dns-svc.yaml /etc/kubernetes/addons


echo "Reloading the system service configuration"
systemctl daemon-reload

echo "Stopping the docker service"
systemctl stop docker.service

echo "Disabling the current service"
systemctl disable docker.service docker-bootstrap.service docker-bootstrap.socket docker.socket


echo "Enabling the new services"
systemctl enable k8s-docker.service k8s-docker-bootstrap.service k8s-docker-bootstrap.socket k8s-docker.socket k8s-etcd.service k8s-flannel.service k8s-master.service

echo "Starting the docker bootstrap service"
systemctl start k8s-docker-bootstrap.socket
systemctl start k8s-docker-bootstrap.service

echo "Pulling necessary etcd Docker image"
docker -H unix:///var/run/docker-bootstrap.sock pull andrewpsuedonym/etcd:2.1.1
echo "Starting the etcd service"
systemctl start k8s-etcd.service

echo "Pulling necessary flannel Docker image"
docker -H unix:///var/run/docker-bootstrap.sock pull andrewpsuedonym/flanneld
echo "Starting the flannel service"
systemctl start k8s-flannel.service

echo "Starting the docker service"
systemctl start k8s-docker.service

echo "Pulling necessary hyperkube Docker image"
docker pull gcr.io/google_containers/hyperkube-arm:v1.3.6
echo "Starting the kubernetes master service"
systemctl start k8s-master.service

