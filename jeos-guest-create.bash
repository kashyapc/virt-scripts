#!/bin/bash

# Kickstart borrowed(& slightly tweaked) from --
# https://raw.github.com/autotest/virt-test/master/shared/unattended/JeOS-17.ks
# Contact: kashyapc@fedoraproject.org
#
#Check if bridging is configured
show_bridge=`brctl show | awk 'NR==2 {print $1}'`
if [ $? -ne 0 ] ; then
	echo "Bridged Networking is not configured, please do so to get an IP similar to your host."
	exit 255
fi 

#check if no. of arguments are 3
if [ "$#" != 3 ]; then
	echo " Please provide the args according to usage"
	echo ""
	echo " usage: "$0 name distro arch" "
	echo ""
        echo "     where 'name'     = f18vm1 "
        echo "     where 'distro'   = f18 "
        echo "     where 'arch'     = x86_64 [OR] i386 "
	echo ""
	exit 255
fi

name=$1
distro=$2
arch=$3


location1=http://dl.fedoraproject.org/pub/fedora/linux/releases/18/Fedora/$arch/os/

echo "Creating domain $name..." 
echo "Disk image will be created as  /var/lib/libvirt/images/$name.qcow2"
echo "Location of the OS sources $location2..."

#Disk Image location
diskimage=/var/lib/libvirt/images/$name.qcow2

#Create the qcow2 disk image with preallocation and 'facllocate'(which pre-allocates all the blocks to a file) it for max. performance
echo "Creating qcow2 disk image.."
qemu-img create -f qcow2 -o preallocation=metadata $diskimage 2G

#NOTE : Uncomment the below comment, *if* you want to allocate all the blocks (and marks them unintialized). But this will remove the sparseness
#fallocate -l `ls -al $diskimage | awk '{print $5}'` $diskimage
echo `ls -lash $diskimage`
#!/bin/bash
cat << EOF > fed.ks
install
text
reboot
lang en_US.UTF-8
keyboard us
network --bootproto dhcp 
rootpw 123456
firewall --disabled
selinux --disabled
timezone --utc America/New_York
firstboot --disable
bootloader --location=mbr --timeout=0 --append="console=tty0 console=ttyS0,115200 rd_NO_PLYMOUTH"
zerombr
poweroff

clearpart --all --initlabel
part / --fstype=ext4 --grow --asprimary --size=1

%packages
gpgme
hardlink
dmidecode
ethtool
tcpdump
tar
bzip2
-yum-utils
-cryptsetup
-vconfig
-dump
-acpid
-mlocate
-stunnel
-rng-tools
-ntfs-3g
-sos
-jwhois
-fedora-release-notes
-pam_pkcs11
-wireless-tools
-rdist
-mdadm
-dmraid
-ftp
-rsync
-system-config-network-tui
-pam_krb5
-nano
-nc
-PackageKit-yum-plugin
-btrfs-progs
-ypbind
-yum-presto
-microcode_ctl
-finger
-krb5-workstation
-ntfsprogs
-iptstate
-fprintd-pam
-irqbalance
-dosfstools
-mcelog
-smartmontools
-lftp
-unzip
-rsh
-telnet
-setuptool
-bash-completion
-pinfo
-rdate
-system-config-firewall-tui
-nfs-utils
-words
-cifs-utils
-prelink
-wget
-dos2unix
-passwdqc
-coolkey
-symlinks
-pm-utils
-bridge-utils
-zip
-eject
-numactl
-mtr
-sssd
-pcmciautils
-tree
-usbutils
-hunspell
-irda-utils
-time
-man-pages
-yum-langpacks
-talk
-wpa_supplicant
-kbd-misc
-kbd
-slang
-authconfig
-newt
-newt-python
-ntsysv
-libnl3
-tcp_wrappers
-quota
-libpipeline
-man-db
-groff
-less
-plymouth-core-libs
-plymouth
-plymouth-scripts
-libgudev1
-ModemManager
-NetworkManager-glib
-selinux-policy
-selinux-policy-targeted
-crontabs
-cronie
-cronie-anacron
-cyrus-sasl
-sendmail
-netxen-firmware
-linux-firmware
-libdaemon
-avahi-autoipd
-libpcap
-ppp
-libsss_sudo
-sudo
-at
-psacct
-parted
-passwd
-bind-utils
-tmpwatch
-bc
-acl
-attr
-traceroute
-mailcap
-quota-nls
-mobile-broadband-provider-info
-audit
-e2fsprogs-libs
-e2fsprogs
-pciutils-libs
-biosdevname
-pciutils
-dbus-glib
-libdrm
-setserial
-lsof
-ed
-cyrus-sasl-plain
-dnsmasq
-system-config-firewall-base
-hesiod
-libpciaccess
-diffutils
-policycoreutils
-m4
-checkpolicy
-procmail
-libuser
-polkit
%end

%post --interpreter /usr/bin/python
import os
os.system('grubby --remove-args="rhgb quiet" --update-kernel=$(grubby --default-kernel)')
os.system('dhclient')
os.system('chkconfig sshd on')
os.system('iptables -F')
os.system('echo 0 > /selinux/enforce')
os.system('echo Post set up finished > /dev/ttyS0')
os.system('echo Post set up finished > /dev/hvc0')
%end
EOF


#Create the guest
if [ "$distro" = f18 ]; then
virt-install --connect=qemu:///system \
    --network=bridge:br0 \
    --initrd-inject=./fed.ks \
    --extra-args="ks=file:/fed.ks console=tty0 console=ttyS0,115200 serial rd_NO_PLYMOUTH" \
    --name=$name \
    --disk path=$diskimage,format=qcow2,cache=none \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --accelerate \
    --os-type linux \
    --os-variant fedora17 \
    --cpuset auto \
    --hvm \
    --location=$location1 \
    --nographics 
fi

