#!/bin/bash
# 
# Copyright (C) 2012 Red Hat Inc.
# Author <kashyap.cv@gmail.com>
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
##################################
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
        echo "     where 'name'= f16vm1 [OR] el6vm2"
        echo "     where 'distro' = rhel6 [OR] rhel5 [OR] f16"
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


location1=http://foo.bar.com/pub/rhel/released/RHEL-6/6.2/Server/$arch/os
location2=http://foo.bar.com/pub/fedora/linux/releases/16/Fedora/$arch/os/

echo "Creating domain $name..." 
echo "Disk image will be created as  /var/lib/libvirt/images/$name.qcow2"
echo "Location of the OS sources $location2..."

#Disk Image location
diskimage=/var/lib/libvirt/images/$name.qcow2

#Create the qcow2 disk image with preallocation and 'facllocate'(which pre-allocates all the blocks to a file) it for max. performance
echo "Creating qcow2 disk image.."
qemu-img create -f qcow2 -o preallocation=metadata $diskimage 20G
fallocate -l `ls -al $diskimage | awk '{print $5}'` $diskimage
echo `ls -lash $diskimage`


if [ "$distro" = rhel6 ]; then
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
    --disk path=$diskimage,format=qcow2 \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --accelerate \
    --hvm \
    --location=$location1 \
    --nographics 

exit 255
#########################################################################

elif [ "$distro" = f16 ]; then
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
    --network=bridge:virbr0 \
    --initrd-inject=./fed.ks \
    --extra-args="ks=file:/fed.ks console=tty0 console=ttyS0,115200 serial rd_NO_PLYMOUTH" \
    --name=$name \
    --disk path=$diskimage,format=qcow2 \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --hvm \
    --location=$location2 \
    --nographics 
fi
