#!/bin/bash

color() {
    STARTCOLOR="\e[$2";
    ENDCOLOR="\e[0m";
    export "$1"="$STARTCOLOR%b$ENDCOLOR".
}
color info 96m
color success 92m.
color warning 93m.
color danger 91m.

if [ `id -u` -ne 0 ]
  then echo Please run this script using sudo!
  exit
fi


FTSLocation=`find / -type d -name 'FreeTAKServer'`
echo $FTSLocation

rm -r $FTSLocation