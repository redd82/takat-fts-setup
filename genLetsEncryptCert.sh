#!/bin/bash
if [ `id -u` -ne 0 ]
  then echo Please run this script using sudo!
  exit
fi

if [ $# -ne 3 ]; then
    echo "Usage: $0 "
    echo "FQDN ${1}"
    echo "Certs location ${2}"
    echo "Keypass ${3}"
    exit 1
fi

HNF=${1}
letencryptcertslocation=${2}
keypass=${3}

echo "Generating new LetsEncrypt Certificates..."
#mkdir $letencryptcertslocation
#certbot certonly --apache --keep-until-expiring --preferred-challenges http -d $serverdir
certbot --non-interactive --agree-tos -m admin@takat.nl --apache --preferred-challenges http -d $HNF
echo "OpenSSL"
openssl pkcs12 -export -in /etc/letsencrypt/live/$HNF/fullchain.pem -inkey /etc/letsencrypt/live/$HNF/privkey.pem -out $HNF-le.p12 -name $HNF -passout pass:$keypass
echo "Moving to $letencryptcertslocation"
mv ./$HNF-le.p12 $letencryptcertslocation

#Importing keystore ./letsencryptcerts/dev-tak-tak1.takat.nl-le.p12 to ./letsencryptcerts/dev-tak-tak1.takat.nl-le.jks...
#Existing entry alias dev-tak-tak1.takat.nl exists, overwrite? [no]:  yes

echo "Running keytool"
#keytool -delete -alias mydomain -keystore keystore.jks
keytool -importkeystore -deststorepass $keypass -destkeystore $letencryptcertslocation/$HNF-le.jks -srcstorepass $keypass -srckeystore $letencryptcertslocation/$HNF-le.p12 -srcstoretype pkcs12