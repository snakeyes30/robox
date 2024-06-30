#!/bin/bash -x

retry() {
  local COUNT=1
  local DELAY=0
  local RESULT=0
  while [[ "${COUNT}" -le 10 ]]; do
    [[ "${RESULT}" -ne 0 ]] && {
      [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput setaf 1
      echo -e "\n${*} failed... retrying ${COUNT} of 10.\n" >&2
      [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput sgr0
    }
    "${@}" && { RESULT=0 && break; } || RESULT="${?}"
    COUNT="$((COUNT + 1))"

    # Increase the delay with each iteration.
    DELAY="$((DELAY + 10))"
    sleep $DELAY
  done

  [[ "${COUNT}" -gt 10 ]] && {
    [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput setaf 1
    echo -e "\nThe command failed 10 times.\n" >&2
    [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput sgr0
  }

  return "${RESULT}"
}

# Install the the EPEL repository.
retry yum --assumeyes --enablerepo=extras install epel-release

# Install Developer Packages
retry yum --assumeyes install archivemount autoconf autofs automake cloog-ppl cmake cpp crypto-utils diffuse eclipse-mylyn-cdt eclipse-mylyn-pde eclipse-mylyn-trac eclipse-mylyn-webtasks eclipse-mylyn-wikitext eclipse-subclipse-graph ElectricFence expect file-devel finger ftp gcc gcc-c++ gcc-gnat gcc-java gcc-objc gcc-objc++ gd gdb-gdbserver geany gedit-plugins git glibc-devel glibc-headers glibc-utils gperf haveged httpd-devel httpd-manual imake inotify-tools iotop iptables-devel iptraf jwhois kernel-headers keyutils-libs-devel krb5-devel libarchive libbsd libbsd-devel libcom_err-devel libevent libevent-devel libevent-doc libevent-headers libffi-devel libgomp libmemcached libselinux-devel libsepol-devel libstdc++-devel libstdc++-docs libtool libuuid-devel libzip lm_sensors lm_sensors-devel lm_sensors-libs lslk m2crypto mc mcelog meld memcached memtest86+ mercurial mod_perl mod_ssl mpfr mysql mysql-bench mysql-connector-java mysql-server nasm ncurses-devel net-snmp net-snmp-devel net-snmp-libs net-snmp-perl net-snmp-python net-snmp-utils nmap numpy openssl-devel oprofile-gui oprofile-jit patch perf perl perl-DBD-MySQL perl-DBI perl-Error perl-Git perl-libs perl-Module-Pluggable perl-Pod-Escapes perl-Pod-Simple perl-Time-HiRes perl-version powertop ppl psutils python-crypto2.6 python-devel python-pip python-ply python-pycparser rsync screen setools-console setroubleshoot setroubleshoot-plugins setroubleshoot-server stunnel sysstat telnet texinfo tokyocabinet tokyocabinet-devel valgrind valgrind-devel wget wireshark wireshark-gnome xmlto xz-devel zlib-devel

# Enable and start the daemons.
chkconfig mysqld on
chkconfig memcached on
service mysqld start
service memcached start

# Setup the mysql root account with a random password.
export PRAND=`openssl rand -base64 18`
mysqladmin --user=root password "$PRAND"

# Allow the root user to login to mysql as root by saving the randomly generated password.
printf "\n\n[mysql]\nuser=root\npassword=$PRAND\n\n" >> /root/.my.cnf

# Create the mytool user and grant the required permissions.
mysql --execute="CREATE USER mytool@localhost IDENTIFIED BY 'aComplex1'"
mysql --execute="GRANT ALL ON *.* TO mytool@localhost"

# Install the python packages needed for the stacie script to run, which requires the python cryptography package (installed via pip).
retry yum --assumeyes install zlib-devel openssl-devel libffi-devel python-pip python-ply python-devel python-pycparser python-crypto2.6 libcom_err-devel libsepol-devel libselinux-devel keyutils-libs-devel krb5-devel

# Install the Python Prerequisites
curl --silent -o cryptography-1.5.2.tar.gz https://files.pythonhosted.org/packages/03/1a/60984cb85cc38c4ebdfca27b32a6df6f1914959d8790f5a349608c78be61/cryptography-1.5.2.tar.gz || \
{ rm -f cryptography-1.5.2.tar.gz ; curl --silent -o cryptography-1.5.2.tar.gz https://archive.org/download/legacy-pip-packages/cryptography-1.5.2.tar.gz ; }

curl --silent -o cffi-1.11.5.tar.gz https://files.pythonhosted.org/packages/e7/a7/4cd50e57cc6f436f1cc3a7e8fa700ff9b8b4d471620629074913e3735fb2/cffi-1.11.5.tar.gz || \
{ rm -f cffi-1.11.5.tar.gz ; curl --location --silent -o cffi-1.11.5.tar.gz https://archive.org/download/legacy-pip-packages/cffi-1.11.5.tar.gz ; }

curl --silent -o enum34-1.1.6.tar.gz https://files.pythonhosted.org/packages/bf/3e/31d502c25302814a7c2f1d3959d2a3b3f78e509002ba91aea64993936876/enum34-1.1.6.tar.gz || \
{ rm -f enum34-1.1.6.tar.gz ; curl --location --silent -o enum34-1.1.6.tar.gz https://archive.org/download/legacy-pip-packages/enum34-1.1.6.tar.gz ; }

curl --silent -o ipaddress-1.0.22.tar.gz https://files.pythonhosted.org/packages/97/8d/77b8cedcfbf93676148518036c6b1ce7f8e14bf07e95d7fd4ddcb8cc052f/ipaddress-1.0.22.tar.gz || \
{ rm -f ipaddress-1.0.22.tar.gz ; curl --location --silent -o ipaddress-1.0.22.tar.gz https://archive.org/download/legacy-pip-packages/ipaddress-1.0.22.tar.gz ; }

curl --silent -o idna-2.7.tar.gz https://files.pythonhosted.org/packages/65/c4/80f97e9c9628f3cac9b98bfca0402ede54e0563b56482e3e6e45c43c4935/idna-2.7.tar.gz || \
{ rm -f idna-2.7.tar.gz ; curl --location --silent -o idna-2.7.tar.gz https://archive.org/download/legacy-pip-packages/idna-2.7.tar.gz ; }

curl --silent -o pyasn1-0.4.4.tar.gz https://files.pythonhosted.org/packages/10/46/059775dc8e50f722d205452bced4b3cc965d27e8c3389156acd3b1123ae3/pyasn1-0.4.4.tar.gz || \
{ rm -f pyasn1-0.4.4.tar.gz ; curl --location --silent -o pyasn1-0.4.4.tar.gz https://archive.org/download/legacy-pip-packages/pyasn1-0.4.4.tar.gz ; }

curl --silent -o six-1.11.0.tar.gz https://files.pythonhosted.org/packages/16/d8/bc6316cf98419719bd59c91742194c111b6f2e85abac88e496adefaf7afe/six-1.11.0.tar.gz || \
{ rm -f six-1.11.0.tar.gz ; curl --location --silent -o six-1.11.0.tar.gz https://archive.org/download/legacy-pip-packages/six-1.11.0.tar.gz ; }

curl --silent -o setuptools-11.3.tar.gz https://files.pythonhosted.org/packages/34/a9/65ef401499e6878b3c67c473ecfd8803eacf274b03316ec8f2e86116708d/setuptools-11.3.tar.gz || \
{ rm -f setuptools-11.3.tar.gz ; curl --location --silent -o setuptools-11.3.tar.gz https://archive.org/download/legacy-pip-packages/setuptools-11.3.tar.gz ; }

sha256sum --quiet --check <<-EOF || { echo "Python package tarball hashes failed to validate ..." ; exit 1 ; }
e90f17980e6ab0f3c2f3730e56d1fe9bcba1891eeea58966e89d352492cc74f4  cffi-1.11.5.tar.gz
eb8875736734e8e870b09be43b17f40472dc189b1c422a952fa8580768204832  cryptography-1.5.2.tar.gz
8ad8c4783bf61ded74527bffb48ed9b54166685e4230386a9ed9b1279e2df5b1  enum34-1.1.6.tar.gz
684a38a6f903c1d71d6d5fac066b58d7768af4de2b832e426ec79c30daa94a16  idna-2.7.tar.gz
b146c751ea45cad6188dd6cf2d9b757f6f4f8d6ffb96a023e6f2e26eea02a72c  ipaddress-1.0.22.tar.gz
f58f2a3d12fd754aa123e9fa74fb7345333000a035f3921dbdaa08597aa53137  pyasn1-0.4.4.tar.gz
a2da967efa9ed2f033d4dc4b3230001e97365b43993fdc744c3c3717c919380e  setuptools-11.3.tar.gz
70e8a77beed4562e7f14fe23a786b54f6296e34344c23bc42f07b15018ff98e9  six-1.11.0.tar.gz
EOF

pip install idna-2.7.tar.gz pyasn1-0.4.4.tar.gz six-1.11.0.tar.gz enum34-1.1.6.tar.gz cffi-1.11.5.tar.gz ipaddress-1.0.22.tar.gz setuptools-11.3.tar.gz cryptography-1.5.2.tar.gz
rm --force idna-2.7.tar.gz pyasn1-0.4.4.tar.gz six-1.11.0.tar.gz enum34-1.1.6.tar.gz cffi-1.11.5.tar.gz ipaddress-1.0.22.tar.gz setuptools-11.3.tar.gz cryptography-1.5.2.tar.gz

printf "export PYTHONPATH=/usr/lib64/python2.6/site-packages/pycrypto-2.6.1-py2.6-linux-x86_64.egg/\n" > /etc/profile.d/pypath.sh
chcon "system_u:object_r:bin_t:s0" /etc/profile.d/pypath.sh
chmod 644 /etc/profile.d/pypath.sh

# Find out how much RAM is installed, and what 50% would be in KB.
TOTALMEM=`free -k | grep -E "^Mem:" | awk -F' ' '{print $2}'`
HALFMEM=`echo $(($TOTALMEM/2))`

# Setup the memory locking limits.
printf "*    soft    memlock    $HALFMEM\n" > /etc/security/limits.d/50-magmad.conf
printf "*    hard    memlock    $HALFMEM\n" >> /etc/security/limits.d/50-magmad.conf

# Fix the SELinux context.
chcon system_u:object_r:etc_t:s0 /etc/security/limits.d/50-magmad.conf

# Create the clamav user to avoid spurious errors when compilintg ClamAV.
useradd clamav

# Disable the default users.
usermod --lock --shell /sbin/nologin clamav
usermod --lock --shell /sbin/nologin vagrant

# Enable sudo for the magma user.
printf "magma\nmagma\n" | passwd magma
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
printf "magma        ALL=(ALL)       NOPASSWD: ALL\n" > /etc/sudoers.d/magma
chmod 0440 /etc/sudoers.d/magma

# Ship with the latest version of magma. For some reason a fully qualified output
# path results in the clone operation performing poorly, so we change directories
# first.
mkdir --parents /home/magma/Lavabit/ && cd /home/magma/Lavabit/
git clone https://github.com/lavabit/magma.git magma
cd $HOME

# Grab a snapshot of the development branch.
cat <<-EOF > "/home/magma/magma-build.sh"
#!/bin/bash

error() {
  if [ \$? -ne 0 ]; then
    printf "\n\nmagma daemon compilation failed...\n\n";
    exit 1
  fi
}

# Temporary [hopefully] workaround to avoid [yet another] bug in NSS.
export NSS_DISABLE_HW_AES=1

# Pull the latest magma repository off Github.
cd /home/magma/Lavabit/magma/; error
git pull; error

# Linkup the magma helper scripts.
mkdir /home/magma/bin/
dev/scripts/linkup.sh; error

# Compile the dependencies into a shared library.
dev/scripts/builders/build.lib.sh all; error

# Reset the sandbox database and storage files.
dev/scripts/database/schema.reset.sh; error

# Enable the anti-virus engine and update the signatures.
dev/scripts/freshen/freshen.clamav.sh 2>&1 | grep -v WARNING | grep -v PANIC; error
sed -i -e "s/virus.available = false/virus.available = true/g" sandbox/etc/magma.sandbox.config

# Ensure the sandbox config uses port 2525 for relays.
sed -i -e "/magma.relay\[[0-9]*\].name.*/d" sandbox/etc/magma.sandbox.config
sed -i -e "/magma.relay\[[0-9]*\].port.*/d" sandbox/etc/magma.sandbox.config
sed -i -e "/magma.relay\[[0-9]*\].secure.*/d" sandbox/etc/magma.sandbox.config
printf "\n\nmagma.relay[1].name = localhost\nmagma.relay[1].port = 2525\n\n" >> sandbox/etc/magma.sandbox.config

# Bug fix... create the scan directory so ClamAV unit tests work.
if [ ! -d 'sandbox/spool/scan/' ]; then
  mkdir -p sandbox/spool/scan/
fi

# Compile the daemon and then compile the unit tests.
make all; error

# Run the unit tests.
dev/scripts/launch/check.run.sh

# If the unit tests fail, print an error, but contine running.
if [ \$? -ne 0 ]; then
  tput setaf 1; tput bold; printf "\n\nsome of the magma daemon unit tests failed...\n\n"; tput sgr0;
  for i in 1 2 3; do
    printf "\a"; sleep 1
  done
  sleep 12
fi

# Alternatively, run the unit tests atop Valgrind.
# Note this takes awhile when the anti-virus engine is enabled.
MAGMA_MEMCHECK=\$(echo \$MAGMA_MEMCHECK | tr "[:lower:]" "[:upper:]")
if [ "\$MAGMA_MEMCHECK" == "YES" ]; then
  dev/scripts/launch/check.vg
fi

# Daemonize instead of running on the console.
# sed -i -e "s/magma.output.file = false/magma.output.file = true/g" sandbox/etc/magma.sandbox.config
# sed -i -e "s/magma.system.daemonize = false/magma.system.daemonize = true/g" sandbox/etc/magma.sandbox.config

# Launch the daemon.
# ./magmad --config magma.system.daemonize=true sandbox/etc/magma.sandbox.config

# Save the result.
# RETVAL=\$?

# Give the daemon time to start before exiting.
sleep 15

# Exit wit a zero so Vagrant doesn't think a failed unit test is a provision failure.
exit \$RETVAL
EOF

# Make the script executable.
chown magma:magma /home/magma/magma-build.sh
chmod +x /home/magma/magma-build.sh

# Setup the logo.
mkdir --parents /home/magma/Pictures/

base64 -d <<-EOF > /home/magma/Pictures/Mark.png
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
LetGFK31Z6ogQ1XNJSp0Dipih6liC6QsCLVW2TXZvmHJzl0vltkA1mKOeftp5Oi6ayunMm0QjJw9
BeU94ES01lpvrR+P+99PbbJp/X/aOUa7Qep28WTb2cb1+zFGa70/r3MP9vd5nX48f9jnoObkznZI
R5taaO9jO6+LHVdrpNF6P1rrP9cYf697LvzMOZFttLGM/3md6a0c1/cnZACazvbeeh9tnKONMTf5
Fda0y7j2Odm9zGV/zc8Yr/lpZ+tHb7+jteP4aef5n3t894s6rq7X1/1ba+2c1+/XjPdrsV774vds
rff5Tuazv+a3zfFe4zmOxzXO8Rrf1XpqroU5v/N529Gfn7/eV+u9jXEpj/Xjut804nh+6/sYy/t4
vsfextpipYy/1/VztGscy6JbjfV6/97aOddT/3kq7s1sy7V+emvtnJvp53j9/h7/ldxtr/Uw7oE8
5/096nm+77lexvi9jNnxmv/r+7Vg4/m5837ePuf73g+ttXG+7cc5hjb3UNmv5/i95+Oez3v+Lm3n
aQzb8vuzL59v9/7rx3i9v7luxvxMf41/7u/lead9uPfPXHhzH/br98fRRjvaOc52XNdF17vXTW/t
+Pm53sFrfa3z93w9vR3HRHaPZeyXDev9uT97W/b3XD/Hh33sy344zwt3n++rHx/vY9q/cX2+9cs4
//nzh3gs1bt5X5z+3x9Imf1+NW71+++///z+NC74BH5fvLcx+Yfj/+b7r/GexfhUj+d/P//r4eC+
P40Lfx/4++vhtPv+k/F/rtt/8/56H5+bW3z/08t8N171cGHP/7qOm69/t36xt/v/tf7cfHw+w2ne
V3Ve/nb95Ot13n8d/38Bq+gRx+PKwDkAAAAASUVORK5CYII=
EOF

# Setup the desktop shortcuts and README file.
mkdir --parents /home/magma/Desktop/

# Setup the link.
cat <<-EOF > /home/magma/Desktop/Lavabit.desktop
#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Link
Icon[en_US]=/home/magma/Pictures/Mark.png
Name[en_US]=Lavabit
URL=/home/magma/Lavabit/
Comment[en_US]=Link to the magma workspace.
Name=Lavabit
Comment=Link to the magma workspace.
Icon=/home/magma/Pictures/Mark.png
EOF

# The Eclipse desktop file needs execution permission to launch.
chmod 755 /home/magma/Desktop/Lavabit.desktop

cat <<-EOF > /home/magma/Desktop/Eclipse.desktop
#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=eclipse
Name[en_US]=Eclipse
Exec=eclipse -data /home/magma/Lavabit
Comment[en_US]=Eclipse Environment
Name=Eclipse
Comment=Eclipse Environment
Icon=/usr/share/icons/hicolor/48x48/apps/eclipse.png
EOF

# The Eclipse desktop file needs execution permission to launch.
chmod 755 /home/magma/Desktop/Eclipse.desktop

cat <<-EOF > /home/magma/Desktop/README

To grab the latest version of magma, and get it configured, run the
~/magma-build.sh script in your home directory. Then launch Eclipse
and start coding.

Or for those who prefer a command line, use the scripts in ~/magma/bin.

EOF

cat <<-EOF > /home/magma/gconf.conf
<gconfentryfile>
<entrylist base="/">
<entry>
  <key>/apps/gnome-power-manager/timeout/sleep_display_ac</key>
  <schema_key>/schemas/apps/gnome-power-manager/timeout/sleep_display_ac</schema_key>
  <value>
    <int>0</int>
  </value>
</entry>
<entry>
  <key>/apps/gnome-screensaver/idle_activation_enabled</key>
  <schema_key>/schemas/apps/gnome-screensaver/idle_activation_enabled</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
<entry>
  <key>/desktop/gnome/session/idle_delay</key>
  <schema_key>/schemas/desktop/gnome/session/idle_delay</schema_key>
  <value>
    <int>120</int>
  </value>
</entry>

<entry>
  <key>/desktop/gnome/interface/gtk_color_scheme</key>
</entry>
<entry>
  <key>/desktop/gnome/background/picture_filename</key>
  <schema_key>/schemas/desktop/gnome/background/picture_filename</schema_key>
  <value>
    <string></string>
  </value>
</entry>

<entry>
  <key>/desktop/gnome/background/picture_opacity</key>
  <schema_key>/schemas/desktop/gnome/background/picture_opacity</schema_key>
  <value>
    <int>100</int>
  </value>
</entry>
<entry>
  <key>/desktop/gnome/background/picture_options</key>
  <schema_key>/schemas/desktop/gnome/background/picture_options</schema_key>
  <value>
    <string>none</string>
  </value>
</entry>
<entry>
  <key>/desktop/gnome/background/primary_color</key>
  <schema_key>/schemas/desktop/gnome/background/primary_color</schema_key>
  <value>
    <string>#000000000000</string>
  </value>
</entry>
<entry>
  <key>/desktop/gnome/background/secondary_color</key>
  <schema_key>/schemas/desktop/gnome/background/secondary_color</schema_key>
  <value>
    <string>#380138013801</string>
  </value>
</entry>


<entry>
  <key>/apps/panel/objects/object_1/action_type</key>
  <schema_key>/schemas/apps/panel/objects/action_type</schema_key>
  <value>
    <string>lock</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/attached_toplevel_id</key>
  <schema_key>/schemas/apps/panel/objects/attached_toplevel_id</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/bonobo_iid</key>
  <schema_key>/schemas/apps/panel/objects/bonobo_iid</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/custom_icon</key>
  <schema_key>/schemas/apps/panel/objects/custom_icon</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/launcher_location</key>
  <schema_key>/schemas/apps/panel/objects/launcher_location</schema_key>
  <value>
    <string>/home/magma/Desktop/Eclipse.desktop</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/locked</key>
  <schema_key>/schemas/apps/panel/objects/locked</schema_key>
  <value>
    <bool>true</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/menu_path</key>
  <schema_key>/schemas/apps/panel/objects/menu_path</schema_key>
  <value>
    <string>applications:/</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/object_type</key>
  <schema_key>/schemas/apps/panel/objects/object_type</schema_key>
  <value>
    <string>launcher-object</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/panel_right_stick</key>
  <schema_key>/schemas/apps/panel/objects/panel_right_stick</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/position</key>
  <schema_key>/schemas/apps/panel/objects/position</schema_key>
  <value>
    <int>282</int>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/tooltip</key>
  <schema_key>/schemas/apps/panel/objects/tooltip</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/toplevel_id</key>
  <schema_key>/schemas/apps/panel/objects/toplevel_id</schema_key>
  <value>
    <string>top_panel</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/use_custom_icon</key>
  <schema_key>/schemas/apps/panel/objects/use_custom_icon</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_1/use_menu_path</key>
  <schema_key>/schemas/apps/panel/objects/use_menu_path</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/action_type</key>
  <schema_key>/schemas/apps/panel/objects/action_type</schema_key>
  <value>
    <string>lock</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/attached_toplevel_id</key>
  <schema_key>/schemas/apps/panel/objects/attached_toplevel_id</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/bonobo_iid</key>
  <schema_key>/schemas/apps/panel/objects/bonobo_iid</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/custom_icon</key>
  <schema_key>/schemas/apps/panel/objects/custom_icon</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/launcher_location</key>
  <schema_key>/schemas/apps/panel/objects/launcher_location</schema_key>
  <value>
    <string>/usr/share/applications/geany.desktop</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/locked</key>
  <schema_key>/schemas/apps/panel/objects/locked</schema_key>
  <value>
    <bool>true</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/menu_path</key>
  <schema_key>/schemas/apps/panel/objects/menu_path</schema_key>
  <value>
    <string>applications:/</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/object_type</key>
  <schema_key>/schemas/apps/panel/objects/object_type</schema_key>
  <value>
    <string>launcher-object</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/panel_right_stick</key>
  <schema_key>/schemas/apps/panel/objects/panel_right_stick</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/position</key>
  <schema_key>/schemas/apps/panel/objects/position</schema_key>
  <value>
    <int>346</int>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/tooltip</key>
  <schema_key>/schemas/apps/panel/objects/tooltip</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/toplevel_id</key>
  <schema_key>/schemas/apps/panel/objects/toplevel_id</schema_key>
  <value>
    <string>top_panel</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/use_custom_icon</key>
  <schema_key>/schemas/apps/panel/objects/use_custom_icon</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_3/use_menu_path</key>
  <schema_key>/schemas/apps/panel/objects/use_menu_path</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/action_type</key>
  <schema_key>/schemas/apps/panel/objects/action_type</schema_key>
  <value>
    <string>lock</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/attached_toplevel_id</key>
  <schema_key>/schemas/apps/panel/objects/attached_toplevel_id</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/bonobo_iid</key>
  <schema_key>/schemas/apps/panel/objects/bonobo_iid</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/custom_icon</key>
  <schema_key>/schemas/apps/panel/objects/custom_icon</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/launcher_location</key>
  <schema_key>/schemas/apps/panel/objects/launcher_location</schema_key>
  <value>
    <string>/usr/share/applications/gedit.desktop</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/locked</key>
  <schema_key>/schemas/apps/panel/objects/locked</schema_key>
  <value>
    <bool>true</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/menu_path</key>
  <schema_key>/schemas/apps/panel/objects/menu_path</schema_key>
  <value>
    <string>applications:/</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/object_type</key>
  <schema_key>/schemas/apps/panel/objects/object_type</schema_key>
  <value>
    <string>launcher-object</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/panel_right_stick</key>
  <schema_key>/schemas/apps/panel/objects/panel_right_stick</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/position</key>
  <schema_key>/schemas/apps/panel/objects/position</schema_key>
  <value>
    <int>314</int>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/tooltip</key>
  <schema_key>/schemas/apps/panel/objects/tooltip</schema_key>
  <value>
    <string></string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/toplevel_id</key>
  <schema_key>/schemas/apps/panel/objects/toplevel_id</schema_key>
  <value>
    <string>top_panel</string>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/use_custom_icon</key>
  <schema_key>/schemas/apps/panel/objects/use_custom_icon</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
<entry>
  <key>/apps/panel/objects/object_5/use_menu_path</key>
  <schema_key>/schemas/apps/panel/objects/use_menu_path</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>


<entry>
  <key>/apps/gnome-terminal/profiles/Default/background_color</key>
  <schema_key>/schemas/apps/gnome-terminal/profiles/Default/background_color</schema_key>
  <value>
    <string>#000000000000</string>
  </value>
</entry>
<entry>
  <key>/apps/gnome-terminal/profiles/Default/foreground_color</key>
  <schema_key>/schemas/apps/gnome-terminal/profiles/Default/foreground_color</schema_key>
  <value>
    <string>#FFFFFFFFFFFF</string>
  </value>
</entry>
<entry>
  <key>/apps/gnome-terminal/profiles/Default/scrollback_lines</key>
  <schema_key>/schemas/apps/gnome-terminal/profiles/Default/scrollback_lines</schema_key>
  <value>
    <int>16536</int>
  </value>
</entry>
<entry>
  <key>/apps/gnome-terminal/profiles/Default/use_theme_colors</key>
  <schema_key>/schemas/apps/gnome-terminal/profiles/Default/use_theme_colors</schema_key>
  <value>
    <bool>false</bool>
  </value>
</entry>
</entrylist>
</gconfentryfile>
EOF

# We need to load the configuration as the magma user, so make the file
# avaialble to we change the owner to magma.
chown magma:magma /home/magma/gconf.conf

# Now we load the file as magma.
su magma --command "gconftool-2 --owner=magma --load /home/magma/gconf.conf"

# With the settings loaded, we no longer need the config file.
rm --force /home/magma/gconf.conf

# Ensure the files created as root, will belong to the magma user.
chown --recursive magma:magma /home/magma/

# Customize the message of the day.
printf "Magma Daemon Desktop Development Environment\nTo download and compile magma, just execute the magma-build.sh script.\n\n" > /etc/motd

# Enable automatic login for the magma user.
sed -i -e "s/\[daemon\]/[daemon]\nAutomaticLoginEnable=true\nAutomaticLogin=magma\n/g" /etc/gdm/custom.conf

# Ensure vagrant can ssh into the machine. Only the developer desktop builds
# use password authentication, which is why the sshd script disables password
# authentication by default. We reverse that actipn here.
sed -i -e "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config

# Hide the clamav and vagrant users when showing the greeter.
sed -i -e "s/\[greeter\]/[greeter]\nExclude=bin,root,daemon,adm,lp,sync,shutdown,"\
"halt,mail,news,uucp,operator,nobody,nobody4,noaccess,postgres,pvm,rpm,"\
"nfsnobody,pcap,clamav,vagrant\n/g" /etc/gdm/custom.conf
