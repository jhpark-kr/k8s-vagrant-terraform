# 마스터 노드 설정
resource "null_resource" "k8s_master" {
  connection {
    type        = "ssh"
    user        = var.vm_user
    private_key = file(var.ssh_private_key_path)
    host        = var.master_ip
  }

  provisioner "file" {
    source      = "../scripts/install_k8s.sh"
    destination = "/tmp/install_k8s.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_k8s.sh",
      "sudo /tmp/install_k8s.sh master",

      # 1. Join 명령어 생성 (sudo 권한 필요)
      "sudo kubeadm token create --print-join-command > /tmp/join_command.sh",
      "sudo chmod 644 /tmp/join_command.sh", # 로컬 PC에서 scp로 가져올 수 있게 권한 변경

      # 2. Flannel 패치 (sudo와 KUBECONFIG 경로 명시)
      "sleep 30",
      "sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl patch ds kube-flannel-ds -n kube-flannel --type='json' -p='[{\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/args/-\", \"value\": \"--iface=enp0s8\"}]'"
    ]
  }

  # 마스터의 join 명령어를 로컬 PC로 다운로드
  provisioner "local-exec" {
    command = "scp -i ${var.ssh_private_key_path} -o StrictHostKeyChecking=no ${var.vm_user}@${var.master_ip}:/tmp/join_command.sh ./join_command.sh"
  }
}

# 워커 노드 설정 (반복문 사용)
resource "null_resource" "k8s_workers" {
  count      = length(var.worker_ips)
  depends_on = [null_resource.k8s_master] # 마스터가 먼저 준비되어야 함

  connection {
    type        = "ssh"
    user        = var.vm_user
    private_key = file(var.ssh_private_key_path)
    host        = var.worker_ips[count.index]
  }

  provisioner "file" {
    source      = "../scripts/install_k8s.sh"
    destination = "/tmp/install_k8s.sh"
  }

  # 로컬로 가져온 join_command.sh를 워커로 업로드
  provisioner "file" {
    source      = "./join_command.sh"
    destination = "/tmp/join_command.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_k8s.sh",
      "sudo /tmp/install_k8s.sh worker",
      # 업로드된 join 명령어 실행
      "sudo sh /tmp/join_command.sh"
    ]
  }
}
