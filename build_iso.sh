#!/bin/bash 


DEBIAN_DL_URL='https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.7.0-amd64-netinst.iso'

ROOTPATH="/home/jakopitsch/debian"
RAW_DEBIAN_ISO="$ROOTPATH/debian_amd64_netinst.iso"
WORKDIR="$ROOTPATH/DEBIAN_ISO_WORKDIR"
PRESEED_ISO="$ROOTPATH/debian-amd64-PRESEED1.iso"

#check  is root?
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

apt install xorriso isolinux -y -q

# Scrub workdir
rm -rf $WORKDIR

if [ ! -f $PRESEED_ISO ]; then
    rm -rf $PRESEED_ISO
fi

# create Rootfolder if not exist
[ ! -d  $ROOTPATH ] && mkdir -v $ROOTPATH || echo "$ROOTPATH existiert schon"

#wget ISO if file not exist
if [ ! -f $RAW_DEBIAN_ISO ]; then
    wget -q $DEBIAN_DL_URL -O $RAW_DEBIAN_ISO --show-progress
fi

# Mount ISO
mkdir -p $WORKDIR/loopdir
mount -o loop $RAW_DEBIAN_ISO $WORKDIR/loopdir/

if ( ! ( mount | grep 'loopdir' ) ); then
  echo "Couldn't mount iso to loopdir"; 
  exit 1;
fi;

# Copy image
mkdir -p $WORKDIR/isodir
cp -rT $WORKDIR/loopdir $WORKDIR/isodir
umount $WORKDIR/loopdir


cat <<EOF > $WORKDIR/isodir/isolinux/isolinux.cfg
TIMEOUT 50
TOTALTIMEOUT 9000

default desktop
label desktop
  say Booting a Desktop install...
  kernel /install.amd/vmlinuz
  append file=/cdrom/ks.preseed auto=true priority=critical vga=788 initrd=/install.amd/initrd.gz locale=de_DE.UTF-8 keymap=de language=de country=DE    # debian-installer=de_DE locale=de_DE kbd-chooser/method=de_DE console-setup/modelcode=pc105 --- quiet
EOF

cat ./deb.preseed > $WORKDIR/isodir/ks.preseed
cat ./firstboot > $WORKDIR/isodir/firstboot

# cd $WORKDIR/isodir
# chmod +w -R install.amd/
# gunzip install.amd/initrd.gz
# echo $WORKDIR/isodir/ks.preseed | cpio -o -H newc -A -F install.amd/initrd
# gzip install.amd/initrd

#rm $WORKDIR/isodir/ks.preseed

find -follow -type f -print0 | xargs --null md5sum > md5sum.txt


# xorriso -as mkisofs -o $PRESEED_ISO \
#   -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
#   -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 \
#   -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
#   -isohybrid-gpt-basdat $WORKDIR/isodir


xorriso -as mkisofs \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -o $PRESEED_ISO \
  $WORKDIR/isodir

# xorriso -as mkisofs -o preseed-debian-10.2.0-i386-netinst.iso \
#         -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
#         -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot \
#         -boot-load-size 4 -boot-info-table isofiles
