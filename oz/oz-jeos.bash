#!/bin/bash
# A script to create joes(just enough operating system) 
# NOTE: once the oz-install is finished, define the xml file and start the guest
# Author - Kashyap Chamarthy <kchamart@redhat.com>

# usage
	if [ $# -ne 2 ]; then
		echo "Usage: $0 <guest-name> <distro>
        'distro': f18, rhel6
        Examples: `basename $0` f18-jeos f19       # create f19
                  `basename $0` f18-jeos f18       # create f18
                  `basename $0` rhel6x-jeos rhel6  # create latest rhel6.x"
		exit 1
	fi

TDLFILE=$2.tdl
LOGFILE=$1.out
LOGFILE2=nwinfo.out
NAME=$1
distro=$2

# This must be run as root

        if [ `id -u` -ne 0 ] ; then
                echo "Please run as 'root' to execute '$0'!"
                exit 1
        fi

# Enable IP forwarding on your host
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

if [ "$distro" = rhel6 ]; then
#create the tdl file(note:the below url will be automatically redirected to our local tree))
function _make_tdl_rhel()  {
cat << EOF > $TDLFILE
<template>
  <name>$NAME</name>
  <os>
    <name>RHEL-6</name>
    <version>4</version>
    <arch>x86_64</arch>
    <install type='url'>
      <url>http://download.foo.bar.redhat.com/pub/rhel/released/RHEL-6/6.4/Server/x86_64/os</url>
    </install>
    <rootpw>redhat</rootpw>
  </os>
  <description>RHEL 6.4 </description>
</template>

EOF
}

# Create the TDL file
_make_tdl_rhel

#exit 255

elif [ "$distro" = f18 ]; then

function _make_tdl_fed()  {
cat << EOF > $TDLFILE
<template>
  <name>$NAME</name>
  <os>
    <name>Fedora</name>
    <version>18</version>
    <arch>x86_64</arch>
    <install type='url'>
      <url>http://dl.fedoraproject.org/pub/fedora/linux/releases/18/Fedora/x86_64/os/</url>
    </install>
    <rootpw>redhat</rootpw>
  </os>
  <description>Fedora 18</description>
</template>
EOF
}


elif [ "$distro" = f19 ]; then

function _make_tdl_fed()  {
cat << EOF > $TDLFILE
<template>
  <name>$NAME</name>
  <os>
    <name>Fedora</name>
    <version>18</version>
    <arch>x86_64</arch>
    <install type='url'>
      <url>http://dl.fedoraproject.org/pub/fedora/linux/releases/19/Fedora/x86_64/os/</url>
    </install>
    <rootpw>redhat</rootpw>
  </os>
  <description>Fedora 18</description>
</template>
EOF
}

# Create the TDL file
_make_tdl_fed

fi
sleep 2

#run the oz script as root
/usr/bin/oz-install -d 4 $TDLFILE 2>&1 | tee $LOGFILE

