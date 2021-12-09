#!/bin/sh

exec >/root/post-install.log 2>&1

set -x

# set authorized keys
rm -rf /root/.ssh
mkdir -p /root/.ssh
chmod 700 /root/.ssh
cat >/root/.ssh/authorized_keys <<EOF
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM0p8Db5YkBi/nGHgSOMp9Q1+aw5ivuwYhz+FjTeFe+ZP7fSNRNmxnRlFS9zBKrcbrjgKb0WariArCKAsNe3TUY= root@6wind
EOF
chmod 600 /root/.ssh/authorized_keys

# update ssh config
cat >/tmp/sshd_config <<EOF
Port 22
Port 29678
Subsystem       sftp    /usr/lib/openssh/sftp-server
GSSAPIAuthentication no
UsePAM no
UseDNS no
PasswordAuthentication no
PermitRootLogin without-password
AllowUsers root
Match Host 127.0.0.0/8,10.0.0.0/8,185.13.181.2
  PasswordAuthentication yes
  AllowUsers *
EOF
sshd -T -f /tmp/sshd_config &&
mv -f /tmp/sshd_config /etc/ssh/sshd_config &&
systemctl restart sshd.service

# upgrade system
cat > /etc/apt/sources.list <<EOF
deb http://httpredir.debian.org/debian stretch main non-free contrib
deb http://httpredir.debian.org/debian stretch-updates main non-free contrib
deb http://httpredir.debian.org/debian stretch-backports main non-free contrib
deb http://httpredir.debian.org/debian-security stretch/updates main non-free contrib
EOF
export DEBIAN_FRONTEND=noninteractive
cat >/etc/apt/apt.conf.d/00InstallRecommends <<EOF
APT::Install-Recommends "false";
EOF
cat >/etc/apt/apt.conf.d/99DpkgForceConf <<EOF
Dpkg::Options::="--force-confdef --force-confold";
EOF
apt-get update -qy
apt-get dist-upgrade -qy
apt-get autoremove --purge ovhkernel* ipmitool
apt-get install -qy linux-image-amd64
packages='
bash-completion
build-essential
curl
dbus
default-jre-headless
diffstat
ethtool
git
gzip
htop
libbz2-dev
libffi-dev
liblzma-dev
libssl-dev
libtool
netfilter-persistent
python-apt
python-dev
python-pip
python-setuptools
python-virtualenv
python-wheel
qemu-kvm
rsync
screen
ssh
strace
strongswan
sudo
tcpdump
telnet
tree
unattended-upgrades
wget
xz-utils
zip
'
apt-get install -qy $packages
