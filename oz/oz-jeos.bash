#!/bin/bash
# A script to create JEOS(Just Enough Operating System) 
#
# NOTE: Once the `oz-install` command is finished, define the xml file
# and start the guest
#
# Author - Kashyap Chamarthy <kchamart@redhat.com> 
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 USA.
 

# Usage
	if [ $# -ne 2 ]; then
		echo "Usage: $0 <guest-name> <distro>
        'distro': f20, f19
        Examples: `basename $0` f20-jeos f20       # create f20 guest"
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

# A few checks so that oz-install won't go crazy with iptables. (Just
# deals with the default virt-network)
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

if [ "$distro" = f20 ]; then

# Create the tdl file(note:the below url will be automatically redirected
# to our local tree))
function _make_tdl_fed()  {
cat << EOF > $TDLFILE
<template>
  <name>$NAME</name>
  <os>
    <name>Fedora</name>
    <version>4</version>
    <arch>x86_64</arch>
    <install type='url'>
      <url>http://dl.fedoraproject.org/pub/fedora/linux/releases/20/Fedora/x86_64/os</url>
    </install>
    <rootpw>fedora</rootpw>
  </os>
  <description>Fedora 20</description>
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
    <version>19</version>
    <arch>x86_64</arch>
    <install type='url'>
      <url>http://dl.fedoraproject.org/pub/fedora/linux/releases/19/Fedora/x86_64/os/</url>
    </install>
    <rootpw>fedora</rootpw>
  </os>
  <description>Fedora 19</description>
</template>
EOF
}

# Create the TDL file
_make_tdl_fed

fi
sleep 2

#run the oz script as root
/usr/bin/oz-install -d 4 $TDLFILE 2>&1 | tee $LOGFILE

