 rm -rvf output/*; PACKER_LOG=1 /home/sam/go/bin/packer build --only=generic-debian11-libvirt  generic-libvirt.json
sudo  virsh vol-delete debian_vagrant_box_image_0_box.img --pool default
 vagrant box add output/generic-debian11-libvirt-.box  --name debian --force
