#!/bin/bash
#title           :enableAQC111.sh
#description     :This script will make aqc111 driver enable in DSM 6.2.
#author          :garynil.tw
#date            :20200608
#version         :0.1  
#usage           :bash enableAQC111.sh
#==============================================================================

while getopts p:a: flag
do
    case "${flag}" in
        a) action=${OPTARG};;
        p) path=${OPTARG};;
        d) driver=${OPTARG};;
    esac
done



SYNOPKG_PKGDEST=$path
[ -z "$path" ] && SYNOPKG_PKGDEST=$PWD

ACTION=$action
[ -z "$action" ] && ACTION="up"

driver_name=$driver
[ -z "$driver" ] && driver_name="aqc111"

echo "Action: $ACTION";
echo "Path: $SYNOPKG_PKGDEST";


modArray=( aqc111 usbnet mii )

for i in "${modArray[@]}"
do
  echo "detecting.. ".$i.ko
  if [ ! -z "$(lsmod | grep $i)" ]
    then
      echo "removed ".$i.ko
      /sbin/rmmod $SYNOPKG_PKGDEST/$i.ko  
  fi
done

sleep(2)
/sbin/insmod $SYNOPKG_PKGDEST/mii.ko
/sbin/insmod $SYNOPKG_PKGDEST/usbnet.ko
/sbin/insmod $SYNOPKG_PKGDEST/aqc111.ko


# Check if aqc111 is enable in mod
check_aqc111=`/sbin/lsmod | grep $driver_name`
if [ -z "$check_aqc111" ]
then
  exit 0;
else
  echo -z "$check_aqc111";
fi

for interface_name in $(ls /sys/class/net)
do
    if [[ ! $interface_name =~ ^eth ]]
    then
      continue
    fi

    driver_location=$(ls -ld /sys/class/net/$interface_name/device/driver)
    interface_has_aqc111_driver=false
    if [ ! -z "$(echo "$driver_location" | grep $driver_name)" ]
    then
      interface_has_aqc111_driver=true
    fi

    echo "interface_has_aqc111_driver is "$interface_has_aqc111_driver

    if [ $interface_has_aqc111_driver = true ]
    then
      config_file=/etc/sysconfig/network-scripts/ifcfg-$interface_name
      config_storage_location=$SYNOPKG_PKGDEST/ifcfg-$interface_name
      if [ -f "$config_file" ] && [ "$ACTION" = "down" ]
      then
        cp $config_file $config_storage_location
      elif [ "$ACTION" = "up" ] && [ -f "$config_storage_location" ]
      then
        cp $config_storage_location $config_file
      fi
      echo "ifconfig is "$interface_name" "$ACTION
      ifconfig $interface_name $ACTION
    fi
done