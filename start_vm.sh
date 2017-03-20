#!/bin/bash

VM_FOLDER=$1
MEM_SIZE=$2
DISCS_COUNT=$3
DC=$4

[ "x$VM_FOLDER" = "x" ] && VM_FOLDER="/tb/vm/422"
[ "x$MEM_SIZE"  = "x" ] && MEM_SIZE=5000
[ "x$DISCS_COUNT"  = "x" ] && DISCS_COUNT=600
[ "x$DC"  = "x" ] && DC=0
SYS_ID=1
TAP_NO=0


OPTS="-k en-us -daemonize" # -nographic

cd "$VM_FOLDER" || exit 1

gen_start() {
    START="qemu-system-x86_64 -boot c -m $MEM_SIZE 
        -enable-kvm -cpu host -balloon virtio
        -drive file=system_disk_$SYS_ID,index=0,media=disk,format=raw 
        -device virtio-scsi-pci,id=scsi0 "

    if [ $DISCS_COUNT -gt 0 ]; then
        for i in `seq 1 $DISCS_COUNT`; do
            
            if (( $i%256 == 0 )); then
                START=`echo "$START -device virtio-scsi-pci,id=scsi${i} "`
            fi

            START=`echo "$START -drive file=disks/disk1_${i},if=none,id=disk1_${i},format=raw -device scsi-hd,id=disk${i},drive=disk1_${i},serial=sn1${i} "`
        done

        if [ "x$DC" = "x1" ]; then
            for i in `seq 1 $DISCS_COUNT`; do
                START=`echo "$START -drive file=disks/disk2_${i},if=none,id=disk2_${i},format=raw -device scsi-hd,drive=disk2_${i},serial=sn2${i} "`
            done
        fi
    fi
    
    echo $START
}

gen_mac_address() {
    echo '00 60 2f'$(od -An -N3 -t xC /dev/urandom) | sed -e 's/ /:/g'
}

MAC1=`cat .mac_${SYS_ID}_1 2>/dev/null` || ( MAC1=$(gen_mac_address) && echo $MAC1 > ".mac_${SYS_ID}_1" )
MAC2=`cat .mac_${SYS_ID}_2 2>/dev/null` || ( MAC2=$(gen_mac_address) && echo $MAC2 > ".mac_${SYS_ID}_2" )

START_CMD=`echo $(gen_start) "$OPTS -net nic,macaddr=$MAC1 -net nic,macaddr=$MAC2 -net tap,ifname=tap$TAP_NO,script=no,downscript=no "`
exec $START_CMD
