#!/bin/bash
#oz script to create joes(just enough operating system) guests
#NOTE: once the oz-install is finished, define the xml file and start the guest
#usage
	if [ $# -ne 1 ]; then
		echo "Usage: $0 <name>"
		exit 1
	fi


TDLFILE=f15_x86_64.tdl
LOGFILE=$1.out
LOGFILE2=nwinfo.out
NAME=$1
#This must be run as root

        if [ `id -u` -ne 0 ] ; then
                echo "Please run as 'root' to execute '$0'!"
                exit 1
        fi

#Enable IP forwarding on your host
cat /proc/sys/net/ipv4/ip_forward

	if [ $? -ne 1 ] ; then
		echo 1 > /proc/sys/net/ipv4/ip_forward
		echo "IP forwarding enabled"
	fi

# A few checks so that oz-install won't go crazy with iptables. (Just deals with the default virt-network)
run_command() {
    echo "# $@"
    eval "$@"
}

(
run_command /usr/bin/virsh net-destroy default
run_command /usr/bin/virsh net-start default
run_command /usr/bin/virsh net-list --all
run_command cat /proc/sys/net/ipv4/ip_forward
) >& $LOGFILE2


#create the tdl file(note:the below url will be automatically redirected to our local tree))
function _make_tdl()  {
cat << EOF > $TDLFILE
<template>
  <name>$NAME</name>
  <os>
    <name>Fedora</name>
    <version>15</version>
    <arch>x86_64</arch>
    <install type='url'>
      <url>http://download.foo.bar.baz.com/pub/fedora/linux/development/15/x86_64/os/</url>
    </install>
    <rootpw>testpwd</rootpw>
  </os>
  <description>Fedora 15</description>
</template>

EOF
}

#Create the TDL file
_make_tdl

sleep 3

#run the oz script as root
/usr/bin/oz-install -d 4 $TDLFILE 2>&1 | tee $LOGFILE

