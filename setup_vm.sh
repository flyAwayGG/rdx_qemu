#!/bin/bash

RAIDIX_IMAGE=$1
MEM=$2
DISKS_COUNT=$3
DC=$4

[ "x$DISKS_COUNT" = "x" ] && DISKS_COUNT=600
[ "x$MEM" = "x" ] && MEM=4096

qemu-img create system_disk_1 10G && \
qemu-system-x86_64 $RAIDIX_IMAGE -hdb system_disk_1 -machine accel=kvm -m $MEM

if [ $DISKS_COUNT -gt 0 ]; then
    mkdir -p disks
    for i in `seq 1 $DISKS_COUNT`; do 
        dd if=/dev/zero of=disks/disk1_$i count=1 bs=1G 
    done
fi

if [ "x$DC" = "x1" ]; then
    cp system_disk_1 system_disk_2
    for i in `seq 1 $DISKS_COUNT`; do 
    	dd if=/dev/zero of=disks/disk2_$i count=1 bs=1G; 
	done
fi