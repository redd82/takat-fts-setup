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

# generate a uuid for the server

if [ $# -ne 7 ]; then
    echo "---"
    echo "Usage: $0 <keypass> <domain e.g. takat.nl> <Countrycode e.g. NL> <state e.g. ZH> <city e.g. RSW> <org e.g. TAKAT> <CA name>"
    echo "---"
    echo "keypass : ${1}"
    echo "Domain : ${2}"
    echo "Country Code : ${3}"
    echo "State : ${4}"
    echo "City : ${5}"
    echo "Organization : TAK"
    echo "Org. Unit : ${6}"
    echo "CA Name : ${7}"
    exit 1
fi

DOCKER_COMPOSE="docker-compose"
HN=`hostname`
HNF=`hostname -f`
uuid=$(uuidgen | tr -d '-')
installfilelocation="~/"

keypass=${1}
domain=${2}
country=${3}
state=${4}
city=${5}
orgunit=${6}
caname=${7}
canameid=$caname-id
myip=`curl ifconfig.me/ip`

printf $success "\n TAKAT FTS Setup script \n"
# printf $info "\nStep 1. Download the official docker image as a zip file from https://tak.gov/products/tak-server \nStep 2. Place the zip file in this tak-server folder.\n"
# printf $warning "\nYou should install this as a user. Elevated privileges (sudo) are only required to clean up a previous install eg. sudo ./scripts/cleanup.sh\n"

#cp $installfilelocation/latest/*.zip .
#cp $installfilelocation/latest/tak-md5checksum.txt .

arch=$(dpkg --print-architecture)

netstat_check () {
	ports=(5432 8089 8443 8444 8446 9000 9001)

	for i in ${ports[@]};
	do
		netstat -lant | grep -w $i
		if [ $? -eq 0 ];
		then
			printf $warning "\nAnother process is still using port $i. Either wait or use 'sudo netstat -plant' to find it, then 'ps aux' to get the PID and 'kill PID' to stop it and try again\n"
			exit 0
		else
			printf $success "\nPort $i is available.."
		fi
	done
}

checksum () {
	printf "\nChecking for FreeTAKServer files in the directory....\n"
	sleep 1
	if [ "$(ls -hl *-RELEASE-*.zip 2>/dev/null)" ];
	then
		printf $warning "SECURITY WARNING: Make sure the checksums match! You should only download your release from a trusted source eg. tak.gov:\n"
		for file in *.zip;
		do
		printf "Computed MD5 Checksum: "
		md5sum $file
		done
		printf "\nVerifying checksums against known values for $file...\n"
		sleep 1
		printf "MD5 Verification: "
		md5sum --ignore-missing -c tak-md5checksum.txt
		if [ $? -ne 0 ];
		then
			printf $danger "SECURITY WARNING: The checksum is not correct, so the file is different. Do you really want to continue with this setup? (y/n): "
			read check
			if [ "$check" == "n" ];
			then
				printf "\nExiting now..."
				exit 0
			elif [ "$check" == "no" ];
			then
				printf "Exiting now..."
			exit 0
			fi
		fi
	else
		printf $danger "\n\tPlease download the release of docker image as per instructions in README.md file. Exiting now...\n\n"
		sleep 1
		exit 0
	fi
}

netstat_check
#checksum

curl -o webmin-setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repos.sh
sh webmin-setup-repos.sh
apt-get install webmin --install-recommends

apt install python3 python3-venv libaugeas0 unzip mc

python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot certbot-apache
ln -s /opt/certbot/bin/certbot /usr/bin/certbot

./scripts/webserver4certs.sh $HNF

NIC=$(route | grep default | awk '{print $8}' | head -n 1)
IP=$HN.$domain

## Set variables for generating CA and client certs
printf $warning "SSL setup.\n"

# Update local env
export COUNTRY=$country
export STATE=$state
export CITY=$city
export ORGANIZATIONAL_UNIT=$orgunit

# Writes variables to a .env file for docker-compose
cat << EOF > .env
STATE=$state
CITY=$city
ORGANIZATIONAL_UNIT=$orgunit
EOF

# Create a letsencrypt certificate
./scripts/genLetsEncryptCert.sh $HNF ./letsencryptcerts $keypass

cp ./letsencryptcerts/$HNF-le.jks ./tak/certs/files

curl -o webmin-setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repos.sh
sudo sh webmin-setup-repos.sh
sudo apt-get install --install-recommends webmin

IP=`ip -4 addr show eth0 | grep -oP "(?<=inet ).*(?=/)"`

export MY_IPA=$IP

wget -qO - bit.ly/freetakhub2 | sudo bash -s -- --ip-addr ${MY_IPA}

sudo systemctl status fts.service fts-ui.service mumble-server.service nodered.service rtsp-simple-server.service

wget https://github.com/FreeTAKTeam/FreeTAKHub/releases/download/v0.2.5/FTH-webmap-linux-0.2.5.zip

unzip FTH-webmap-linux-0.2.5.zip -d ./

sudo chmod +x ./FTH-webmap-linux-0.2.5/FTH-webmap-linux-0.2.5