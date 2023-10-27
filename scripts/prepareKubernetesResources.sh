#!/bin/bash

# Define ingress_alias
vm_location=`curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/location?api-version=2017-08-01&format=text"`
dns_prefix=`hostname | sed 's/-vm//'`
export ingress_alias=${dns_prefix}.${vm_location}.cloudapp.azure.com

# Install packages
sudo yum install -y yum-utils git wget nfs-utils cloud-utils-growpart gdisk

wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz && \
tar xvf helm-v3.12.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin

curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# Grow OS Disk 

sudo growpart /dev/sda 2
sudo xfs_growfs /

# Swap disabled
sudo swapoff -a

# Forwarding IPv4 and letting iptables see bridged traffic 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Installing container runtime
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo sed -i "s/containerd.sock/containerd.sock --exec-opt native.cgroupdriver=systemd/g" /usr/lib/systemd/system/docker.service
sudo chown $USER /var/run/docker.sock
sudo systemctl daemon-reload
sudo systemctl start docker
sudo systemctl enable docker

# Installing kubeadm, kubelet and kubectl
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet-1.26.1 kubeadm-1.26.1 kubectl-1.26.1 --disableexcludes=kubernetes
sudo systemctl enable --now kubelet
sudo systemctl start kubelet

# deploy cluster with kubeadm
# create a config file
cat <<EOF | tee kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v1.26.1
networking:
  podSubnet: "192.168.0.0/16"
  serviceSubnet: "192.169.0.0/16"
  dnsDomain: "cluster.local"
apiServer:
 certSANs:
 - "192.168.0.1"
 - "192.168.0.4"
 - "$ingress_alias"
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
maxPods: 300
podsPerCore: 0
evictionHard:
  memory.available: "500Mi"
  nodefs.available: "1Gi"
  imagefs.available: "1Gi"
evictionMinimumReclaim:
  memory.available: "0Mi"
  nodefs.available: "500Mi"
  imagefs.available: "500Mi"
EOF

sudo sed -i 's/"cri"/""/g' /etc/containerd/config.toml

# deploy
sudo kubeadm init --v=6 --config kubeadm-config.yaml 

# Define kube config to access the cluster
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install cluster networking CNI(Calico).
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml -O
#kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
#curl https://projectcalico.docs.tigera.io/manifests/custom-resources.yaml -O
kubectl create -f custom-resources.yaml

# Configure NFS
sudo mkdir -p /export/viya-share/pvs
sudo mkdir -p /export/viya-share/data
sudo chmod -R 777 /export/viya-share

sudo dnf install nfs-utils

sudo systemctl start nfs-server.service
sudo systemctl enable nfs-server.service

echo "/export/viya-share    *(rw,sync,no_root_squash,no_all_squash)" | sudo tee /etc/exports
sudo systemctl restart nfs-server.service
kubectl create namespace nfs-client

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --version 4.0.8 \
    --namespace nfs-client \
    --set nfs.server="localhost" \
    --set nfs.path="/export/viya-share/pvs" \
    --set nfs.mountOptions="{noatime, nodiratime, 'rsize=262144', 'wsize=262144'}" \
    --set storageClass.archiveOnDelete="false" \
    --set storageClass.name="sas"
	
kubectl patch storageclass sas -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
NodeN=`kubectl get nodes | cut -d ' ' -f 1 | tail -1`
kubectl taint node $NodeN node-role.kubernetes.io/control-plane:NoSchedule-

# Configure Ingress

kubectl create namespace ingress-nginx

cat <<EOF | tee ingress_nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  labels:
    name: ingress-nginx-controller
spec:
  type: NodePort
  ports:
    - port: 80
      nodePort: 30080
      name: http
    - port: 443
      nodePort: 30443
      name: https
  selector:
    name: ingress-nginx-controller
EOF

kubectl -n ingress-nginx apply -f ingress_nodeport.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/baremetal/deploy.yaml

