#!/bin/bash
#
# Vittorio Franco Libertucci 
location="https://azuresupport.blob.core.windows.net/linux/"
#########################
#                       #  
# Verify distro         #
#                       #
#########################

command1="mkdir -p /var/empty/sshd"
command2="chmod 711 /var/empty/sshd"


which python  > /dev/null 2>&1
python_status=`echo $?`  


#echo $python_status

timest=`date +%d-%h-%Y_%H:%M:%S`

if [ "${python_status}" -eq 0 ];  then
#       echo "python is installed"
        distro=`python -c 'import platform ; print platform.dist()[0]'`
        
		date
        echo "VM `uname -n` - Linux distro" $distro
                echo "                    ."
else
        distro=$(awk '/DISTRIB_ID=/' /etc/*-release | sed 's/DISTRIB_ID=//' | tr '[:upper:]' '[:lower:]')

echo $distro
fi

#####


if [ "${distro}" = "Ubuntu" ]; then
echo "not a valid file on this distro"
exit

elif [ "${distro}" = "SuSE" ]; then
echo "not a valid file on this distro"
exit

#centos

elif [[ "${distro}" = "centos"  && -e /etc/os-release ]]; then 
        osver=`grep -i version_id /etc/os-release|awk -F'"' '{print $2}'`;echo $osver
        echo "this is centos" $osver

        if [ $osver = "7" ]; then
                echo "OS = $osver"
                sshstop="/bin/systemctl stop sshd"
                sshstart="/bin/systemctl start sshd"
                sshstatus="/bin/systemctl status sshd"
        fi

elif [[ "${distro}" = "centos"  && ! -e /etc/os-release ]]; then
        osver=`grep -i release /etc/centos-release|awk -F' ' '{print $3}'`;echo $osver
        echo "this is centos" $osver
if [ $osver = 6.6 ] || [ $osver = 6.5 ] || [ $osver = 6.6 ] || [ $osver = 6.7 ]; then
                echo "OS = $osver"
                sshstop="service sshd stop"
                sshstart="service sshd start"
		sshstatus="service sshd status"
                
        fi


elif [[ "${distro}" = redhat && -e /etc/redhat-release ]]; then
        osver=`grep -i release /etc/redhat-release|awk -F' ' '{print $7}'`;echo $osver
        echo "this is centos" $osver
if [ $osver = 6.6 ] || [ $osver = 6.5 ] || [ $osver = 6.6 ] || [ $osver = 6.7 ]; then
             echo "OS = $osver"
                sshstop="service sshd stop"
                sshstart="service sshd start"
		sshstatus="service sshd status"
        fi
else
echo "Distro $distro currently not tested"
exit
fi

$command1
$command2
$sshstop
$sshstart
$sshstatus
#$sshrestart2 2> /dev/null
exit

