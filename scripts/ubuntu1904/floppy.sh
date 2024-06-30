#!/bin/bash -eux

printf 'blacklist floppy\n' > /etc/modprobe.d/floppy.conf

# Then run this instead to rebuild all of the install 
# kernels without the floppy module.
for kernel in /boot/config-*; do 
  [ -f "$kernel" ] || continue
  KERNEL=${kernel#*-}
  mkinitramfs -o "/boot/initrd.img-${KERNEL}.img" "${KERNEL}" || exit 1
done



