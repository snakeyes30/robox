# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "lavabit/magma-ubuntu1604"
  config.vm.network :private_network, :auto_config => false, :autostart => false, :libvirt__network_name => "vagrant-libvirt", :libvirt__always_destroy => false
  
  config.vm.provider :libvirt do |v, override|
    v.qemu_use_session = false
    v.video_vram = 256
    v.memory = 2048
    v.cpus = 2
    v.management_network_name = "vagrant-libvirt"
    v.management_network_keep = true
    v.management_network_autostart = false
  end

  config.vm.provider :hyperv do |v, override|
    v.maxmemory = 2048
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.provider :virtualbox do |v, override|
    v.gui = false
    v.customize ["modifyvm", :id, "--memory", 2048]
    v.customize ["modifyvm", :id, "--cpus", 2]
  end

  ["vmware_fusion", "vmware_workstation", "vmware_desktop"].each do |provider|
    config.vm.provider provider do |v, override|
      v.gui = false
      v.vmx["memsize"] = "2048"
      v.vmx["numvcpus"] = "2"
      v.vmx["cpuid.coresPerSocket"] = "1"
    end
  end

end
