# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64" # Ubuntu 22.04 LTS

  # 노드 정의 (Master 1, Worker 3)
  nodes = {
    "k8s-master" => { :ip => "192.168.56.10", :cpus => 2, :mem => 4096 },
    "k8s-worker-1" => { :ip => "192.168.56.11", :cpus => 2, :mem => 2048 },
    "k8s-worker-2" => { :ip => "192.168.56.12", :cpus => 2, :mem => 2048 },
    "k8s-worker-3" => { :ip => "192.168.56.13", :cpus => 2, :mem => 2048 }
  }

  nodes.each do |name, conf|
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: conf[:ip]
      
      ssh_pub_key = File.readlines(File.expand_path('~/.ssh/id_rsa.pub')).first.strip
      node.vm.provision "shell", inline: <<-SHELL
        mkdir -p /home/vagrant/.ssh
        echo "#{ssh_pub_key}" >> /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh
        chmod 700 /home/vagrant/.ssh
        chmod 600 /home/vagrant/.ssh/authorized_keys
      SHELL

      node.vm.provider "virtualbox" do |vb|
        vb.memory = conf[:mem]
        vb.cpus = conf[:cpus]
        # GUI가 필요 없으므로 headless 모드
        vb.gui = false
        # Extension Pack이 없을 때 발생할 수 있는 USB 컨트롤러 충돌 방지
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
      end
    end
  end
end
