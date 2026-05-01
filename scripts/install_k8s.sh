#!/bin/bash
# scripts/install_k8s.sh

# 1. 스왑 오프 (K8s 필수)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. 컨테이너 런타임(containerd) 설치 및 설정
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# 3. K8s 컴포넌트 설치
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# --- 추가할 자동화 로직 ---

# 추가1-1. Kubelet이 eth1(192.168.56.x)을 사용하도록 강제 설정
LOCAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
# 만약 인터페이스 이름이 eth1이라면 enp0s8 대신 eth1로 적어주세요.
echo "KUBELET_EXTRA_ARGS=--node-ip=$LOCAL_IP" | sudo tee /etc/default/kubelet
sudo systemctl restart kubelet

# 4. 역할별 초기화 (Master vs Worker)
if [ "$1" == "master" ]; then
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.56.10
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    # 네트워크 플러그인 (Flannel) 설치
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    # 추가1-2. Master 노드인 경우에만 Flannel 인터페이스 패치 실행

    # Flannel이 설치될 때까지 잠시 대기
    sleep 30 
    # kubectl이 준비되었는지 확인 후 Flannel DaemonSet 수정
    kubectl patch ds kube-flannel-ds -n kube-flannel --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--iface=enp0s8"}]'
else
    echo "Worker node ready. Please run kubeadm join command manually or via Terraform output."
fi
