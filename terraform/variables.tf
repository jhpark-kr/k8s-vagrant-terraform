variable "ssh_private_key_path" {
  description = "로컬 환경의 SSH 개인키 경로 (예: ~/.ssh/id_rsa)"
  type        = string
}

variable "vm_user" {
  description = "Vagrant 기본 유저"
  default     = "vagrant"
}

variable "master_ip" {
  default = "192.168.56.10"
}

variable "worker_ips" {
  type    = list(string)
  default = ["192.168.56.11", "192.168.56.12", "192.168.56.13"]
}
