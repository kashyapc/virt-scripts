#!/usr/bin/python
#-------------------------------------------------------------
# Original idea -- Rich Jones<rjones@redhat.com> --
    # -https://rwmj.wordpress.com/2010/08/30/python-script-to-replace-templates-in-configuration-files-in-vms/
# Modified by  -- Kashyap Chamarthy<kchamrt@redhat.com>
# PURPOSE: To replace hostname in a guest using guestfish
# Please read the comments.

# *****WARNING**** : This should not be executed on a LIVE vm
#-------------------------------------------------------------


image = "/var/lib/libvirt/images/rhel6test.qcow2"

#root_filesystem = "/dev/sda4"
root_filesystem = "/dev/VolGroup/lv_root"

filename = "/etc/sysconfig/network"

pattern = "HOSTNAME=(.*)"
replacement = "HOSTNAME=rootconf2012.foo.bar.com"


# Import some standard python modules
import tempfile
import os
import fileinput
import shutil
import sys
import re

# Import the guestfs module
import guestfs


# Create a libguestfs handle.
g = guestfs.GuestFS ()

# Add the disk image.
g.add_drive (image)

# NOTE:the libguestfs handle should be launched *after* adding the
# drive(s), and *before* any other commands are run. This launches the
# qemu subprocess.
g.launch ()

# Set the trace flag so that we can see each libguestfs call
g.set_trace (1)

# To access the filesystem in the disk image, mount it. (NOTE: both
# block-devices and LVMs are detected)
g.mount_options ("", root_filesystem, "/")

#Create a temporary directory to edit the file. 
tmpdir = tempfile.mkdtemp ()
tmpfile = os.path.join (tmpdir, "filename")

# Copy the file to a temporary location
g.download (filename, tmpfile)

# Edit the pattern w/ replacement
for line in fileinput.FileInput (tmpfile, inplace=1):
        
    line = re.sub(pattern, replacement, line)
    print line,

# Upload the file
g.upload (tmpfile, filename)

# Unmount all the file system(s).
g.umount_all ()

# This will write any data buffered in memory to disk 
# NOTE: This is very important to do. 
g.sync ()

# Remove the temporary directory created.
shutil.rmtree (tmpdir)

# Exit
sys.exit(0)
