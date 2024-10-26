if [ `id -u` -ne 0 ]
  then echo Please run this script using sudo!
  exit
fi

if [ $# -ne 1 ]; then
#    echo "Usage: $0 <url> "
    echo "Usage: $0 "
    echo "FQDN ${1}"
    exit 1
fi

HNF=${1}

#Create a config for the Apache virtual server..
systemctl stop apache2
echo "Preparing Apache webserver for $HNF"
mkdir /var/www/$HNF
mkdir /var/www/$HNF/packages/
cp ./index.html /var/www/$HNF/index.html

sed -i -e 's/%fullhostname%/'$HNF'/g' /var/www/$HNF/index.html
cp ./apache-template.conf /etc/apache2/sites-available/$HNF.conf
sed -i -e 's/%fullhostname%/'$HNF'/g' /etc/apache2/sites-available/$HNF.conf
ln -s /etc/apache2/sites-available/$HNF.conf /etc/apache2/sites-enabled/$HNF.conf
echo "Restarting Apache webserver..."
systemctl start apache2
