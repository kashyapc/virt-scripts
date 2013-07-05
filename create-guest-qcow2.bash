#!/bin/bash
# 
# Copyright (C) 2013 Red Hat Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#--------------------------------------------
# Script to auto create/install unattended Virtual Machines (with bridging)
# 1)Note: Bridging should be configured on the host to allow guests to be in the same subnet as hosts
# 2)Creting a bridge, refer this: http://wiki.libvirt.org/page/Networking
# 3)The kickstart file contains minimal fedora pkgs like core and text internet
# 4)Also adds a serial console

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
        echo "     where 'name'= f19vm1 [OR] el7vm2"
        echo "     where 'distro' = rhel7 [OR] rhel6 [OR] f19"
        echo "     where 'arch'   = x86_64 [OR] i386"
	echo ""
	exit 255
fi

# check if /export/vmimgs dir exists
#if [ ! -d /export/vmimgs ] ; then
#	echo "'/export/vmimgs' directory does not exist(to store vm images). Please create that."
#	exit 255
#fi

name=$1
distro=$2
arch=$3


location1=http://foo.bar.redhat.com/pub/rhel/nightly/latest-RHEL-7/compose/Server/x86_64/os/
location2=http://foo.bar.redhat.com/pub/rhel/released/RHEL-6/6.4/Server/$arch/os
location3=http://dl.fedoraproject.org/pub/fedora/linux/releases/19/Fedora/$arch/os/

echo "Creating domain $name..." 
echo "Disk image will be created as  /var/lib/libvirt/images/$name.qcow2"

#Disk Image location
diskimage=/var/lib/libvirt/images/$name.qcow2
#diskimage=/export/vmimgs2/$name.qcow2

#Create the qcow2 disk image with preallocation and 'fallocate'(which pre-allocates all the blocks to a file) it for max. performance
echo "Creating qcow2 disk image.."
qemu-img create -f qcow2 -o preallocation=metadata $diskimage 10G
#fallocate -l `ls -al $diskimage | awk '{print $5}'` $diskimage
echo `ls -lash $diskimage`


if [ "$distro" = rhel7 ]; then
#Create the minimal kickstart file for RHEL
cat << EOF > rhel.ks
install
text
reboot
lang en_US.UTF-8
keyboard us
network --bootproto dhcp
rootpw testpwd
firewall --enabled --ssh
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr --append="console=tty0 console=ttyS0,115200 rd_NO_PLYMOUTH"
zerombr
clearpart --all --initlabel
autopart

%packages
@core
%end
EOF


#Create the guest
virt-install --connect=qemu:///system \
    --network=bridge:br0 \
    --initrd-inject=./rhel.ks \
    --extra-args="ks=file:/rhel.ks console=tty0 console=ttyS0,115200" \
    --name=$name \
    --disk path=$diskimage,format=qcow2,cache=none \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --accelerate \
    --cpuset auto \
    --os-type linux \
    --os-variant rhel7 \
    --hvm \
    --location=$location1 \
    --nographics 

exit 255
#########################################################################

elif [ "$distro" = rhel6 ]; then
#Create the minimal kickstart file for RHEL
cat << EOF > rhel.ks
install
text
reboot
lang en_US.UTF-8
keyboard us
network --bootproto dhcp
rootpw testpwd
firewall --enabled --ssh
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr --append="console=tty0 console=ttyS0,115200 rd_NO_PLYMOUTH"
zerombr
key --skip
clearpart --all --initlabel
autopart

%packages
@core
EOF


#Create the guest
virt-install --connect=qemu:///system \
    --network=bridge:virbr0 \
    --initrd-inject=./rhel.ks \
    --extra-args="ks=file:/rhel.ks console=tty0 console=ttyS0,115200" \
    --name=$name \
    --disk path=$diskimage,format=qcow2,cache=none \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --accelerate \
    --cpuset auto \
    --os-type linux \
    --os-variant rhel6 \
    --hvm \
    --location=$location2 \
    --nographics

exit 255
#########################################################################


elif [ "$distro" = f19 ]; then
#Create Minimal kickstart file for Fedora
cat << EOF > fed.ks
install
text
reboot
lang en_US.UTF-8
keyboard us
network --bootproto dhcp
rootpw testpwd
firewall --enabled --ssh
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr --append="console=tty0 console=ttyS0,115200 rd_NO_PLYMOUTH"
zerombr
clearpart --all --initlabel
autopart

%packages
@core
%end
EOF

# Run the VM
virt-install --connect=qemu:///system \
    --network=network:default \
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
    --location=$location3 \
    --nographics 
fi
