#!/bin/bash
#
#Vittorio Franco Libertucci
#
#
#	CLI procedure that performs following
#	The attaching of OS disks can occur only between VM's in the same region.
#	Ensure you run this in the same region as the broken vm
#
#
#	takes input parameter of a vmname
#	obtain the VM's os disk name
#	delete the VM - but keep disks
#	Attach VMs os disk to this VM
#	perform fsck on newly attached disk
#
echo "This script will delete the VM you have specified"
echo "If it's the last or only VM in a Cloud Service, you will lose the IP Address"
echo "Unless you are using a Fixed IP Address. If you want to keep the IP you can add a temporary VM"
echo "to this cloud service before continuing with this - control c - to break out"
echo " "
echo " "

vm=$1
thisvm=`uname -n`
echo $vm


#Add an inital check that $vm and $thisvm are in same region else exit


thisvmloc=`azure vm show $thisvm|grep Location`
vmloc=`azure vm show $vm|grep Location`
this="$(echo $thisvmloc | sed 's/\"//g')"
remvm="$(echo $vmloc | sed 's/\"//g')"

if [[ "$this" != "$remvm" ]]; then echo "VMs not in same Region exiting"; else echo "VMs in same Region"; fi
exit

#exit
# Configure asm node
azure config mode asm


#list all OS disk in subscription
#azure vm disk list

#List disks for $vm
#azure vm disk list $vm
#azure vm disk list $vm  --json | grep name

#Find out the VM's OS disk name
osdiskname=`azure vm show $vm | grep "OSDisk name" | awk '{ print $4 }'`
disk="$(echo $osdiskname | sed 's/\"//g')"

#Check which LUNs occupied on this vm
echo "Note current Disks attached to this vm"
azure vm disk list $thisvm > /var/tmp/scripts/logs/"$vm"_before_disk_attach.txt
find /sys/devices/ -name 'sd*' > /var/tmp/scripts/logs/"$vm"_lun_before_disk_attach.txt

fdisk -l  > /var/tmp/scripts/logs/"$vm"_parts_before.txt

#azure vm delete --help (this will list the help for this command)
# -b, --blob-delete        Remove image and disk blobs
echo "Will delete effected VM but will retain blob"
azure vm delete $vm


#Before attaching $disk to this VM check that the disk is no longer attached to $vm
#From the output look at the output "usageDetails hostedServiceName"
#azure vm disk show $disk

lock=`azure vm disk show $disk|grep hostedServiceName`

#If $lock is empty then disk can be attached , if $lock is not empty then disk can not be attached as it's attached still

until [ -z "$lock" ] 

        do

        lock=`azure vm disk show $disk|grep hostedServiceName`
        echo "Disk not free...waiting 10 seconds"

sleep 10

done

echo "disk is free"


#Attach disks
azure vm disk attach $thisvm $disk

#Check which LUNs occupied on this vm
echo "Note the LUN where disk is attached for VM" $vm and $disk
azure vm disk list $thisvm
azure vm disk list $thisvm > /var/tmp/scripts/logs/"$vm"_after_disk_attach.txt
find /sys/devices/ -name 'sd*' > /var/tmp/scripts/logs/"$vm"_lun_after_disk_attach.txt

#fsck (find out the attached disk)
#if target OS is oracle (mount) check release
#partitions are on different parts.

fdisk -l  > /var/tmp/scripts/logs/"$vm"_parts_after.txt
diff /var/tmp/scripts/logs/"$vm"_parts_before.txt /var/tmp/scripts/logs/"$vm"_parts_after.txt > /var/tmp/logs/"$vm"_diff.txt


grep  ^"> /dev" /var/tmp/logs/"$vm"_diff.txt | awk '{ print $2 }' >  /var/tmp/logs/"$vm"_parts.txt

TimeStamp=`date +%d-%h-%Y_%H`
mkdir /osrecovery$TimeStamp

cat /var/tmp/logs/"$vm"_parts.txt | while read part
        do
        mount $part /osrecovery$TimeStamp
                if [[ -e \/osrecovery"$TimeStamp"\/etc\/passwd ]]; then
                echo "Password file exist"
                parttofsck=$part
		echo $parttofsck $part
                umount /osrecovery$TimeStamp
                else 
                echo "This partition does not contain passwd file - not an os disk"
                umount /osrecovery$TimeStamp
                fi
done

fsck -yM $part



#Then detach from the local VM
#0 = lun number

#lun=`diff /var/tmp/scripts/logs/"$vm"_before_disk_attach.txt  /var/tmp/scripts/logs/"$vm"_after_disk_attach.txt | awk '{ print $3 }'`
#lunno=`diff /var/tmp/scripts/logs/"$vm"_lun_before_disk_attach.txt /var/tmp/scripts/logs/"$vm"_lun_after_disk_attach.txt`
lunno=`diff /var/tmp/scripts/logs/"$vm"_lun_before_disk_attach.txt /var/tmp/scripts/logs/"$vm"_lun_after_disk_attach.txt | awk -F "target" '{ print $2}' | awk -F ":" '{ print $6}' | awk -F "/" '{ print $1}'`

lunno=`diff /var/tmp/scripts/logs/"$vm"_lun_before_disk_attach.txt /var/tmp/scripts/logs/"$vm"_lun_after_disk_attach.txt | awk -F "target" '{ print $2}' | awk -F ":" '{ print $6}' | awk -F "/" '{ print $1}'|sed '/^\s*$/d'|sort -u`
azure vm disk detach $thisvm $lunno

exit

#azure vm list | awk '{ print $2 }'



#
#References
#Cant create VM from OS Disks
https://github.com/Azure/azure-xplat-cli/issues/1816
