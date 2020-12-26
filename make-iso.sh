#!/bin/bash 

# Usage:
# Download Debian ISO and set RAW_DEBIAN_ISO to the absolute path of the ISO location
# Create a Debian preseed file (the attached preseed file works but needs your root publickey specified in the last line) and set PRESEED_FILE to the absolute path of the preseed file location
# Run this script as root to slipstream the preseed file into the ISO

RAW_DEBIAN_ISO='~/debian-7.6.0-amd64-netinst.iso'
WORKDIR='~/DEBIAN_ISO_WORKDIR'
PRESEED_FILE='~/preseed.cfg'
PRESEED_ISO='~/debian-7.6.0-amd64-PRESEED.iso'

# Scrub workdir
rm -rf $WORKDIR

# Mount ISO
mkdir -p $WORKDIR/loopdir
mount -o loop $RAW_DEBIAN_ISO $WORKDIR/loopdir/

if ( ! ( mount | grep 'loopdir' ) ); then
  echo "Couldn't mount iso to loopdir"; 
  exit 1;
fi;

# Copy image
mkdir -p $WORKDIR/isodir
rsync -a -H --exclude=TRANS.TBL $WORKDIR/loopdir/ $WORKDIR/isodir
umount $WORKDIR/loopdir

# Hax the initrd
mkdir -p $WORKDIR/irmod
cd $WORKDIR/irmod
gzip -d < $WORKDIR/isodir/install.amd/initrd.gz | cpio --extract --make-directories --no-absolute-filenames
cp $PRESEED_FILE $WORKDIR/irmod/preseed.cfg
find . | cpio -H newc --create | gzip -9 > $WORKDIR/isodir/install.amd/initrd.gz

# Fix md5sum
md5sum `find $WORKDIR/isodir/ -follow -type f` > $WORKDIR/isodir/md5sum.txt

# Create ISO
# IMPORTANT: the arguments passed to the -b and -c flags should be RELATIVE paths to the last argument (which should be an absolute path)
genisoimage -o $PRESEED_ISO -r -J -no-emul-boot -boot-load-size 4 -boot-info-table -input-charset utf-8 -b isolinux/isolinux.bin -c isolinux/boot.cat $WORKDIR/isodir/

exit 0
