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
      "sudo /tmp/install_k8s.sh master"
    ]
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

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_k8s.sh",
      "sudo /tmp/install_k8s.sh worker"
    ]
  }
}
