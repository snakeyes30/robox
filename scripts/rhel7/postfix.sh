#!/bin/bash -eux

# Check whether the install media is mounted, and if necessary mount it.
if [ ! -f /media/media.repo ]; then
  mount /dev/cdrom /media
fi

# The postfix server for message relays. The checkpolicy, policycoreutils and the-
# policycoreutils-python packages are needed to compile the selinux module below.
yum --assumeyes install postfix checkpolicy policycoreutils policycoreutils-python

# Postfix opportunistic TLS relay.
printf "smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt\n" >> /etc/postfix/main.cf
printf "smtp_tls_ciphers = high\n" >> /etc/postfix/main.cf
printf "smtp_tls_loglevel = 2\n" >> /etc/postfix/main.cf
printf "smtp_tls_mandatory_ciphers = medium\n" >> /etc/postfix/main.cf
printf "smtp_tls_mandatory_protocols = SSLv3 TLSv1\n" >> /etc/postfix/main.cf
printf "smtp_tls_protocols = !SSLv2 !SSLv3\n" >> /etc/postfix/main.cf
printf "smtp_tls_security_level = may\n" >> /etc/postfix/main.cf
printf "tls_daemon_random_bytes = 128\n" >> /etc/postfix/main.cf
printf "tls_random_bytes = 255\n" >> /etc/postfix/main.cf
printf "tls_random_reseed_period = 1800s\n\n" >> /etc/postfix/main.cf

# Postfix size limits.
printf "body_checks_size_limit = 134217728\n"
printf "mailbox_size_limit = 0\n"
printf "message_size_limit = 134217728\n"
printf "virtual_mailbox_limit = 0\n\n"

# Configure the postfix hostname and origin parameters.
printf "\ninet_interfaces = localhost\n" >> /etc/postfix/main.cf
printf "inet_protocols = ipv4\n" >> /etc/postfix/main.cf
printf "myhostname = relay.magma.localdomain\n" >> /etc/postfix/main.cf
printf "myorigin = magma.localdomain\n" >> /etc/postfix/main.cf
printf "transport_maps = hash:/etc/postfix/transport\n" >> /etc/postfix/main.cf

# Configure postfix to listen for relays on port 2525 so it doesn't conflict with magma.
sed -i -e "s/^smtp\([ ]*inet\)/127.0.0.1:2525\1/" /etc/postfix/master.cf

# Classify port 2525 as as SMTP so Postfix can bind to it running afoul of selinux.
semanage port -a -t smtp_port_t -p tcp 2525

# Setup logrotate so it only stores 7 days worth of logs.
printf "/var/log/maillog {\n\tdaily\n\trotate 7\n\tmissingok\n}\n" > /etc/logrotate.d/postfix

# Fix the SELinux context for the postfix logrotate config.
chcon system_u:object_r:etc_t:s0 /etc/logrotate.d/postfix

#printf "\nmagma.localdomain         smtp:[127.0.0.1]:7000\n" >> /etc/postfix/transport
#printf "magmadaemon.com         smtp:[127.0.0.1]:7000\n" >> /etc/postfix/transport
postmap /etc/postfix/transport

# So it gets started automatically.
systemctl enable postfix.service && systemctl start postfix.service
