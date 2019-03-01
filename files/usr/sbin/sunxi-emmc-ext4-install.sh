#!/bin/sh

# Copyright (c) 2018-2019 Antony Antony <antony@phenome.org>

set -xue

USD_ROOT=/dev/mmcblk0p1
EMMC_DEVICE=/dev/mmcblk2
CMDLINE=`cat /proc/cmdline`

grep ${USD_ROOT} /proc/cmdline || (echo "Unknown root device can not find ${USD_ROOT} in ${CMDLINE}"; exit)

echo "Micro SD root install to eMMC"

DEVICE=${EMMC_DEVICE}
QUOTED_DEVICE=$(echo "${DEVICE}" | sed 's:/:\\\/:g')
#LASTSECTOR=$(( 32 * $(parted ${DEVICE} unit s print -sm | awk -F":" "/^${QUOTED_DEVICE}/ {printf (\"%0d\", ( \$2 * 99 / 3200))}") -1 ))
mkdir -p /mnt/root
# total sectors  15117183
# boot end
BOOTEND=65535
FIRSTROOTSTART=65536
FIRSTROOTEND=294911
SECONDROOTSTART=294912
SECONDROOTEND=557055
DATASTART=557056
#parted -s ${DEVICE} -- mklabel ext41
#parted -s ${DEVICE} -- mkpart primary ext4 8192s ${LASTSECTOR}s
#partprobe ${DEVICE}
echo 'type=83' | sfdisk ${DEVICE}
blockdev --rereadpt ${DEVICE}
mkfs.ext4 -qF ${DEVICE}p1
dd if=/boot/sun50i-h5-nanopi-neo-plus2-u-boot-with-spl.bin of=${DEVICE} bs=8k seek=1 conv=fsync
EMMCROOT=/mnt/emmc-root
mkdir -p  ${EMMCROOT}
mount ${DEVICE}p1 ${EMMCROOT}

rsync -aPv --exclude=/dev/* --exclude=/proc/* --exclude=/sys/* \
        --exclude=/media/* --exclude=/mnt/* --exclude=/run/* \
        --exclude=/dev/tmp/* --exclude=/mnt/* /* ${EMMCROOT}/

sync
rm -fr ${EMMCROOT}/boot/boot.scr
rsync -aPv  /boot/sun50i-h5-nanopi-neo-plus2-boot-emmc-p1.scr ${EMMCROOT}/boot/boot.scr
sync
umount ${EMMCROOT}
