#!/bin/bash

# Create a qcow2 disk image
/usr/bin/qemu-img create -f qcow2 -o preallocation=metadata /export/vmimgs/glacier.qcow2 8G

# Create an unattended minimal guest install using a qcow2 disk image
virt-install --connect=qemu:///system \
    --network=bridge:br0 \
    --initrd-inject=/var/tmp/fed-minimal.ks \
    --extra-args="ks=file:/fed-minimal.ks console=tty0 console=ttyS0,115200" \
    --name=glacier \
    --disk path=/export/vmimgs/glacier.qcow2,format=qcow2 \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --hvm \
    --location=http://download.fedora.redhat.com/pub/fedora/linux/releases/15/Fedora/x86_64/os/ \
    --nographics

