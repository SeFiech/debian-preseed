# debian-pressed

Script from Site: https://finalrewind.org/interblag/entry/debian-preseeding-usb-stick-with-uefi/

Preseeding is a handy way of automating Debian installations. With a proper preseed.cfg, a Debian installation can run completely unattended in about 10 minutes, including setup of users, sudo and SSH keys.

For future reference, here are the things I found helpful
custom post-installation commands

d-i preseed/late_command executes arbitrary commands after the installation is completed. I use this to set up SSH keys and sudo, like so:

in-target mkdir -p /root/.ssh /home/derf/.ssh; \
in-target wget -O /root/.ssh/authorized_keys https://.../keys-root; \
in-target wget -O /home/derf/.ssh/authorized_keys https://.../keys; \
in-target chmod 700 /root/.ssh /home/derf/.ssh; \
in-target chmod 600 /root/.ssh/authorized_keys /home/derf/.ssh/authorized_keys; \
in-target chown -R derf:derf /home/derf/.ssh; \
apt-install sudo; in-target adduser derf sudo

Adding preseed.cfg to virt-install images

--initrd-inject embeds arbitrary files into the root of the installation image. So, for preseeding, just add --initrd-inject .../preseed.cfg to your virt-install invocation.
Adding preseed.cfg to USB images (with UEFI support)

This is a bit more tricky. Basically: Download and unpack ISO, inject preseed.cfg into initrd, refresh md5sums, rebuild ISO and add UEFI support.

The following script should do the job for most amd64 systems. Usage: ./mkpreseediso debian-x.y.z-amd64-netinst.iso
