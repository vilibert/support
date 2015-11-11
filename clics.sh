#!/bin/sh
#
#Vittorio Franco Libertucci
#Azure Support
#
# clics =  Command Line Interface Customer Support
#
############################

vm=$1
file=$2
log=/var/tmp/scripts/log/


#if [[ "$1" == "help" && "$1" == "--help" ]]; then
if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        echo ""
        echo ""
        echo " Used to  inject into you Linux VM a script in an attempt to perform an \"option\""
        echo ""
        echo ""
        echo " Example: ./clics vmname <option>"
        echo " "
        echo " option can be one of <reset> <firewall> <health>  <recreate_empty> <reboot> <fixdisk>" 
        #echo " option can be <reset> <firewall> <health> or <recreate_empty> <reboot> <fixdisk> <reset_fstab> <set_perms>" 
        echo " "
        echo ""
        echo ""
        echo "<reset>  - this will restart sshd daemon and attempt local test to the ssh port 22, it also turns off firewall"
        echo "	if a restart does not resolve the problem a clean sshd_config file is copied making a backup of the original"
        echo ""
        echo ""
        echo "<firewall> - will turn off the firewall in the guest"
        echo ""
        echo ""
        echo "<health> - captures generic VM information and writes to the log"
        echo ""
        echo ""
        echo "<recreate_empty> - Recreate the file /var/empty/sshd and restart sshd - if the files is missing it prevents connections"
        echo ""
        echo ""
	echo "<reboot> - Perform an init 6 on the target VM"
	echo ""
	echo ""
	echo "<fixdisk> - Perform fsck on VM with file system errors"
        echo ""
        echo ""


exit
elif [ -z "$1" ] || [ -z "$2" ] 
  then
  clear
  echo " No vm name or option supplied - please supply vm name and option"
  echo " "
  echo " option can be <reset> <firewall> <health> or <recreate_empty> " 
  echo " "
  echo " Example: ./clics vmname <option>"
  echo " "
  echo " clics --help or -h for more information"
  echo " "
exit
fi

if [[ "$2" != "reset" && "$2" != "firewall" && "$2" != "health" && "$2" != "recreate_empty" && "$2" != "fixdisk" ]]; then
  echo "No valid option supplied "
  echo " option can be <reset> <firewall> <health> or <recreate_empty> " 
  echo " "
  echo " Example: ./clics vmname <option>"
exit
fi

if [[ "$2" == "fixdisk" ]]; then
clear
	/var/tmp/scripts/fixdisk.sh $1
else


#Working
TimeStamp=`date +%d-%h-%Y_%H:%M:%S`
#echo "azure vm extension set $vm CustomScriptForLinux Microsoft.OSTCExtensions 1.3 -i '{"fileUris":["http://azuresupport.blob.core.windows.net/linux/$file.sh\"], \"commandToExecute\": \"sh $file.sh\", "timestamp": "'$TimeStamp'"}' > "$log"$vm.log" > /var/tmp/command_to_run.sh

 echo "azure vm extension set $vm CustomScriptForLinux Microsoft.OSTCExtensions 1.3 -i '{\"fileUris\":[\"http://azuresupport.blob.core.windows.net/linux/$file.sh\"], \"commandToExecute\": \" sh $file.sh \", \"timestamp\": \"'$TimeStamp'\"}' > "$log$vm".log" > /var/tmp/command_to_run.sh

	#Run the extension 
	chmod 755 /var/tmp/command_to_run.sh
	sh /var/tmp/command_to_run.sh
fi
exit

#Refernces
#https://azure.microsoft.com/en-us/blog/automate-linux-vm-customization-tasks-using-customscript-extension/



