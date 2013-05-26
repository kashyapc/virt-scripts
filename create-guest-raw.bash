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
#--------------------------------------------
# Script to auto create/install unattended Virtual Machines (with bridging)
# 1)Note: Bridging should be configured on the host to allow guests to be in the same subnet as hosts
# 2)Creting a bridge, refer this: http://wiki.libvirt.org/page/Networking
# 3)The kickstart file contains minimal fedora pkgs like core and text internet
# 4)Also adds a serial console


# check if Bridged Networking is configured

show_bridge=`brctl show | awk 'NR==2 {print $1}'`
if [ $? -ne 0 ] ; then
	echo "Bridged Networking is not configured, please do so to get an IP similar to your host."
	exit 255
fi 
#check if no. of arguments are 3
if [ "$#" != 3 ]; then
	echo " Please provide the args according to usage"
	echo ""
	echo " usage: "$0 domname distro arch" "
	echo ""
        echo "     where 'domname'= f15vm1 [OR] el6vm2"
        echo "     where 'distro' = rhel6 [OR] f15"
        echo "     where 'arch'   = x86_64 [OR] i386"
	echo ""
	exit 255
fi

# check if /export/vmimgs dir exists
if [ ! -d /export/vmimgs ] ; then
	echo "'/export/vmimgs' directory does not exist(to store vm images). Please create that."
	exit 255
fi

domname=$1
distro=$2
arch=$3

location1=http://foo.bar.redhat.com/pub/rhel/released/RHEL-6/6.4/Server/$arch/os/
locatin2=http://dl.fedoraproject.org/pub/fedora/linux/releases/18/Fedora/$arch/os/


#create the image file
#to enable raw disk format, uncomment the below line
#vmimage=`qemu-img create -f raw /export/vmimgs/$domname.img 6G`
#qcow2 format
#vmimage=`qemu-img create -f qcow2 /export/vmimgs/$domname.qcow2 8G`

echo "Creating domain $domname..." 
echo "Image is here  $vmimage"
echo "Location of the OS sources $location..."


if [ "$distro" = rhel6 ]; then
virt-install --connect=qemu:///system \
    --network=bridge:br0 \
    --initrd-inject=/export/rhel.ks \
    --extra-args="ks=file:/rhel.ks console=tty0 console=ttyS0,115200" \
    --name=$domname \
    --disk /export/vmimgs/$domname.img,size=10,cache=none \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --accelerate \
    --cpuset auto \
    --os-type linux \
    --os-variant rhel6 \
    --hvm \
    --location=$location1 \
    --nographics 

exit 255
#########################################################################

elif [ "$distro" = f18 ]; then

virt-install --connect=qemu:///system \
    --network=bridge:br0 \
    --initrd-inject=/export/fed-minimal.ks \
    --extra-args="ks=file:/fed-minimal.ks console=tty0 console=ttyS0,115200" \
    --name=$domname \
    --disk /export/vmimgs/$domname.img,size=20,cache=none \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --accelerate \
    --cpuset auto \
    --os-type linux \
    --os-variant fedora18 \
    --hvm \
    --location=$location2 \
    --nographics 

fi

