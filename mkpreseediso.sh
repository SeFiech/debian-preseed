#!/bin/sh

set -e

ISO="$1"
WD="$(mktemp -d)"

7z x -o$WD $ISO

cd $WD

gunzip install.amd/initrd.gz
cp /tmp/preseed.cfg .
echo preseed.cfg | cpio -o -H newc -A -F install.amd/initrd
rm preseed.cfg
gzip install.amd/initrd

find -follow -type f -print0 | xargs --null md5sum > md5sum.txt

cd

xorriso -as mkisofs -o $ISO -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 \
-boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
-isohybrid-gpt-basdat $WD
