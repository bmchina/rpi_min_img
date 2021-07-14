#!/bin/sh
sudo apt-get install -y dosfstools dump parted kpartx
df=`df -P | grep /dev/root | awk '{print $3}'`
df=`echo $df |awk '{print int($1*1.1+57344)}'`
sudo dd if=/dev/zero of=raspberrypi.img bs=1K count=$df
sudo parted raspberrypi.img --script -- mklabel msdos
sudo parted raspberrypi.img --script -- mkpart primary fat32 8192s 122879s
sudo parted raspberrypi.img --script -- mkpart primary ext4 122880s -1
loopdevice=`sudo losetup -f --show raspberrypi.img`
device=`sudo kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"
partBoot="${device}p1"
partRoot="${device}p2"
sudo mkfs.vfat $partBoot
sudo mkfs.ext4 $partRoot
sudo mount -t vfat $partBoot /media
sudo cp -rfp /boot/* /media/
sudo umount /media
sudo chattr +d raspberrypi.img
sudo mount -t ext4 $partRoot /media/
cd /media
sudo dump -h 0 -0uaf - / | sudo restore -rf -
cd
sudo umount /media
sudo kpartx -d $loopdevice
sudo losetup -d $loopdevice
