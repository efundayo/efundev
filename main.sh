#!/bin/bash

function deploy {
rm -rf webserver  > /dev/null 2>&1 && mkdir webserver  && rm -rf dbserver  > /dev/null 2>&1 && mkdir dbserver 
git add webserver/
git add dbserver/
 
cat <<'EOF' >  create_icinga2db.sh
#!/bin/bash

password=mysqlrootpassword

mysqladmin -u root password $password

EOF


chmod +x  create_icinga2db.sh

cp  create_icinga2db.sh  dbserver/create_icinga2db.sh

git add  dbserver/create_icinga2db.sh
git add  create_icinga2db.sh

cat <<'EOF' >  webserver/WebDockerfile 

#
# Ubuntu Dockerfile
#
# https://github.com/dockerfile/ubuntu
#
## MOSUDI Using Ubuntu 14.04 aws ec2 instance 
## MOSUDI cd /home/ubuntu/
## MOSUDI git clone github.com/dockerfile/ubuntu
## MOSUDI mv /home/ubuntu/ubuntu/dockerfile  /home/ubuntu/ubuntu/dockerfile_backup
## MOSUDI mv /home/ubuntu/WebDockerfile  /home/ubuntu/ubuntu/dockerfile
## MOSUDI docker build -t="dockerfile/ubuntu" /home/ubuntu/ubuntu/
## MOSUDI docker run -itd --rm dockerfile/ubuntu

# Pull base image.
FROM ubuntu:14.04

#ARG DEBIAN_FRONTEND=noninteractive

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y \
		build-essential \
		byobu \
		curl \
		git \
		htop \
		man \
		python-software-properties \
		software-properties-common \ 
		unzip \
		vim \
		wget \

  && wget -O - https://packages.icinga.com/icinga.key | apt-key add -  
RUN echo "deb http://packages.icinga.com/ubuntu icinga-trusty main " >> /etc/apt/sources.list
RUN echo "deb-src http://packages.icinga.com/ubuntu icinga-trusty main " >> /etc/apt/sources.list  && \
 apt-get update && apt-get install -y \
		apache2 \
		bash-completion \
		icinga2 \
                nagios-plugins  \
		openssh-server \
		php5 \
		php5-intl \
		php5-mcrypt php5-imagick  \
		python \
		tzdata \
#RUN sed -i 's/;date.timezone =/date.timezone = Africa\/Lagos/g' /etc/php5/apache2/php.ini && \
  && icinga2 daemon -C && \
  service apache2 start -C && \
 
# END OF ADDED LINES
  rm -rf /var/lib/apt/lists/*

# Add files.
ADD root/.bashrc /root/.bashrc
ADD root/.gitconfig /root/.gitconfig
ADD root/.scripts /root/.scripts

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]


EOF

git add webserver/WebDockerfile

cat <<'EOF' >  webserver/web_lab_server.sh
#!/bin/bash

docker run -itd --rm dockerfile/ubuntu > web_lab

web_lab="$(cat web_lab )" 
docker commit  $web_lab mosudi/webserver  > /dev/null 2>&1 
docker run -h webserver.mosudi -p 800:80 -p 223:22 -itd mosudi/webserver /bin/bash >web_lab_container
web_lab_container="$(cat web_lab_container )"
docker inspect $web_lab_container  | grep Hostname | grep -v null| cut -d '"' -f 4 | tail -1 >web_lab_container_hostname 
web_lab_container_hostname="$(cat web_lab_container_hostname)"
docker inspect $web_lab_container  | grep IPAddress | grep -v null| cut -d '"' -f 4 | head -1 >web_lab_container_ip
web_lab_container_ip="$( cat web_lab_container_ip)"
echo "$(cat web_lab_container_ip)    $(cat web_lab_container_hostname) " >> /etc/hosts
docker exec -it $web_lab_container bash -c "echo '$web_lab_container_ip    $web_lab_container_hostname '  >> /etc/hosts"
docker inspect $web_lab_container | grep Gateway | grep -v null| cut -d '"' -f 4 | head -1 >lab_gateway_ip
lab_gateway_ip="$(cat lab_gateway_ip)"
lab_gateway_public_hostname=
lab_gateway_public_ip=
lab_gateway_hostname="$(hostname -f)"
docker exec -it $web_lab_container bash -c "echo '$lab_gateway_ip    $lab_gateway_hostname '  >> /etc/hosts"

docker exec -it $web_lab_container bash -c "echo '$lab_gateway_public_ip    $lab_gateway_public_hostname '  >> /etc/hosts"

docker exec -it $web_lab_container bash -c "sed -i 's/;date.timezone =/date.timezone = Africa\/Lagos/g' /etc/php5/apache2/php.ini "

docker exec -it $web_lab_container bash -c "sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config "

docker exec -it $web_lab_container bash -c " echo -e 'password\npassword' | passwd  root  "

docker exec -it $web_lab_container bash -c 'mv /etc/icinga2/conf.d/services.conf /etc/icinga2/conf.d/services.conf_backup'
docker exec -it $web_lab_container bash -c 'mv /etc/icinga2/conf.d/hosts.conf /etc/icinga2/conf.d/hosts.conf_backup'
services="$(cat webservices.conf)"
hosts="$(cat webhosts.conf)"
docker exec -it $web_lab_container bash -c "echo '$services' >/etc/icinga2/conf.d/services.conf"
docker exec -it $web_lab_container bash -c "echo '$hosts' >/etc/icinga2/conf.d/hosts.conf"
#46a67e40ff6f
docker exec -it $web_lab_container bash -c "service ssh start  "
docker exec -it $web_lab_container bash -c "service apache2 start  "


docker exec -it $web_lab_container bash -c "icinga2 object list --type Host "
docker exec -it $web_lab_container bash -c "icinga2 object list --type Service "
docker exec -it $web_lab_container bash -c "icinga2 daemon -C "


#getting the host docker ip address
#ip addr show |grep 172.17.| grep -v null | awk '{print $2}'|cut -d '/' -f 1


EOF

chmod +x webserver/web_lab_server.sh

git add webserver/web_lab_server.sh

cat <<'EOF' >  webserver/webhosts.conf


object Host NodeName {
  import "generic-host"
  address = "127.0.0.1"
  address6 = "::1"
  vars.os = "Linux"
  vars.http_vhosts["http"] = {
    http_uri = "/"
  }
  vars.notification["mail"] = {
    groups = [ "icingaadmins" ]
  }
}

EOF
git add webserver/webhosts.conf

cat <<'EOF' >  webserver/webservices.conf



		apply Service for (http_vhost => config in host.vars.http_vhosts) {
		  import "generic-service"

		  check_command = "http"

		  vars += config
		}



EOF

git add webserver/webservices.conf

cat <<'EOF' >  dbserver/dbservices.conf

apply Service "MySQL - DB Monitor" {
				   import "generic-service"
				   check_command = "mysql"
				   vars.mysql_database = "mysql"
				   assign where host.name == NodeName
				}


EOF

git add dbserver/dbservices.conf

cat <<'EOF' >  dbserver/dbhosts.conf


	object Host NodeName {
		import "generic-host"
	//      address = "dbserver.mosudi"
		address = "127.0.0.1"
		address6 = "::1"
		vars.os = "Linux"
		check_command = "mysql"
		vars.mysql_database = "mysql"
		vars.mysql_username = "root"
		vars.mysql_password = "mysqlrootpassword"
		}
EOF

git add dbserver/dbhosts.conf

cat <<'EOF' >  dbserver/db_lab_server.sh
#!/bin/bash

docker run -itd --rm dockerfile/ubuntu > db_lab
db_lab="$(cat db_lab )"
docker commit  $db_lab mosudi/mysqlserver  > /dev/null 2>&1 
docker run -h dbserver.mosudi -itd -p 801:80 -p 222:22 mosudi/mysqlserver /bin/bash >db_lab_container
db_lab_container="$(cat db_lab_container )"
docker inspect $db_lab_container  | grep Hostname | grep -v null| cut -d '"' -f 4 | tail -1 >db_lab_container_hostname
db_lab_container_hostname="$(cat db_lab_container_hostname)"
docker inspect $db_lab_container  | grep IPAddress | grep -v null| cut -d '"' -f 4 | head -1 >db_lab_container_ip
db_lab_container_ip="$(cat db_lab_container_ip)"
echo "$db_lab_container_ip    $db_lab_container_hostname " >> /etc/hosts
docker exec -it $db_lab_container bash -c 'echo "$db_lab_container_ip    $db_lab_container_hostname " >> /etc/hosts'
docker inspect $db_lab_container | grep Gateway | grep -v null| cut -d '"' -f 4 | head -1 >lab_gateway_ip
lab_gateway_ip="$(cat lab_gateway_ip)"
lab_gateway_public_hostname=
lab_gateway_public_ip=
lab_gateway_hostname="$(hostname -f)"
docker exec -it $db_lab_container bash -c "echo '$lab_gateway_ip    $lab_gateway_hostname '  >> /etc/hosts"

docker exec -it $db_lab_container bash -c "echo '$lab_gateway_public_ip    $lab_gateway_public_hostname '  >> /etc/hosts"
#create_icinga2db="$(cat ~/create_icinga2db.sh)"
#docker exec -it $db_lab_container bash -c "echo '$create_icinga2db' > ~/create_icinga2db.sh && chmod +x ~/create_icinga2db.sh && source ~/create_icinga2db.sh  "
create_icinga2db="$(cat create_icinga2db.sh)"
docker exec -it $db_lab_container bash -c "echo '$create_icinga2db' > /root/create_icinga2db.sh "
docker exec -it $db_lab_container bash -c "chmod +x /root/create_icinga2db.sh"
docker exec -it $db_lab_container bash -c "export PATH=/root/:$PATH  "
docker exec -it $db_lab_container bash -c " create_icinga2db.sh  "


docker exec -it $db_lab_container bash -c "sed -i 's/;date.timezone =/date.timezone = Africa\/Lagos/g' /etc/php5/apache2/php.ini "
docker exec -it $db_lab_container bash -c "sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config "

docker exec -it $db_lab_container bash -c "sed -i 's/bind-address.*/bind-address     = 0.0.0.0/g' /etc/mysql/my.cnf "

docker exec -it $db_lab_container bash -c " echo -e 'password\npassword' | passwd  root "

docker exec -it $db_lab_container bash -c 'mv /etc/icinga2/conf.d/services.conf /etc/icinga2/conf.d/services.conf_backup'
docker exec -it $db_lab_container bash -c 'mv /etc/icinga2/conf.d/hosts.conf /etc/icinga2/conf.d/hosts.conf_backup'
services="$(cat dbservices.conf)"
hosts="$(cat dbhosts.conf)"
docker exec -it $db_lab_container bash -c "echo '$services' >/etc/icinga2/conf.d/services.conf"
docker exec -it $db_lab_container bash -c "echo '$hosts' >/etc/icinga2/conf.d/hosts.conf"

docker exec -it $db_lab_container bash -c "service ssh start   "
docker exec -it $db_lab_container bash -c "service mysql start  "


docker exec -it $db_lab_container bash -c "icinga2 object list --type Host "
docker exec -it $db_lab_container bash -c "icinga2 object list --type Service "
docker exec -it $db_lab_container bash -c "icinga2 daemon -C "


#getting the host docker ip address
#ip addr show |grep 172.17.| grep -v null | awk '{print $2}'|cut -d '/' -f 1

#mysql> CREATE USER 'root'@'%' IDENTIFIED BY 'mysqlrootpassword';
# mysql --user="$user" --password="$password" --database="$database" --execute="DROP DATABASE $user; CREATE DATABASE $database;"
#Query OK, 0 rows affected (0.00 sec)

#mysql> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
#Query OK, 0 rows affected (0.00 sec)

#mysql> FLUSH PRIVILEGES;
#Query OK, 0 rows affected (0.00 sec)

#mysql> quit;
#Bye




#0e76f3dfa25c
#docker exec -it $db_lab_container -c "echo '$create_icinga2db' > ~/create_icinga2db.sh && chmod +x ~/create_icinga2db.sh && source ~/create_icinga2db.sh  "


EOF

chmod +x dbserver/db_lab_server.sh
git add dbserver/db_lab_server.sh



cat <<'EOF' > dbserver/DBDockerfile 


#
# Ubuntu Dockerfile
#
# https://github.com/dockerfile/ubuntu
#
## MOSUDI Using Ubuntu 14.04 aws ec2 instance 
## MOSUDI cd /home/ubuntu/
## MOSUDI git clone github.com/dockerfile/ubuntu
## MOSUDI mv /home/ubuntu/ubuntu/dockerfile  /home/ubuntu/ubuntu/dockerfile_backup
## MOSUDI mv /home/ubuntu/WebDockerfile  /home/ubuntu/ubuntu/dockerfile
## MOSUDI docker build -t="dockerfile/ubuntu" /home/ubuntu/ubuntu/
## MOSUDI docker run -itd --rm dockerfile/ubuntu

# Pull base image.
FROM ubuntu:14.04

#ARG DEBIAN_FRONTEND=noninteractive

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y \
		build-essential \
		byobu \
		curl \
		git \
		htop \
		man \
		python-software-properties \
		software-properties-common \ 
		unzip \
		vim \
		wget \

  && wget -O - https://packages.icinga.com/icinga.key | apt-key add -  
RUN echo "deb http://packages.icinga.com/ubuntu icinga-trusty main " >> /etc/apt/sources.list
RUN echo "deb-src http://packages.icinga.com/ubuntu icinga-trusty main " >> /etc/apt/sources.list  && \
 apt-get update && apt-get install -y \
		bash-completion \
		icinga2 \
		mysql-server \
        	mysql-client \
                nagios-plugins  \
		openssh-server \
		php5 \
		php5-intl \
		php5-mcrypt php5-imagick  \
		python \
		tzdata \
#RUN sed -i 's/;date.timezone =/date.timezone = Africa\/Lagos/g' /etc/php5/apache2/php.ini && \
  && service mysql start -C && \
  icinga2 daemon -C && \
  password=mysqlrootpassword && \
  mysqladmin -u root password $password && \
  mysql -u root -p$password -e "CREATE USER 'root'@'%' IDENTIFIED BY $password;" && \
  mysql -u root -p$password -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'; FLUSH PRIVILEGES;" && \


# END OF ADDED LINES
  rm -rf /var/lib/apt/lists/*

# Add files.
ADD root/.bashrc /root/.bashrc
ADD root/.gitconfig /root/.gitconfig
ADD root/.scripts /root/.scripts

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]

EOF

git add dbserver/DBDockerfile

cat <<'EOF' > icinga2master_dbbackup.sh
#!/bin/bash

#rm -rf /root/backup/icinga2master  > /dev/null 2>&1 && mkdir /root/backup/icinga2master
 
USER="root"
PASSWORD="mysqlrootpassword"
OUTPUT=" /root/backup/icinga2master"
 
rm "$OUTPUT/*gz" > /dev/null 2>&1
 
databases=`mysql --user=$USER --password=$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
 
for dbitem in $databases; do
    if [[ "$dbitem" != "information_schema" ]] && [[ "$dbitem" != _* ]] ; then
        echo "Dumping database: $dbitem"
        mysqldump --force --opt --user=$USER --password=$PASSWORD --databases $dbitem > $OUTPUT/`date +%Y%m%d`.$dbitem.sql
        gzip $OUTPUT/`date +%Y%m%d`.$dbitem.sql
    fi
done

EOF

chmod +x icinga2master_dbbackup.sh
git add icinga2master_dbbackup.sh

cat <<'EOF' > dbserverbackup.sh
#!/bin/bash

#rm -rf /root/backup/dbserver  > /dev/null 2>&1 && mkdir /root/backup/dbserver
 
DBHOST="dbserver.mosudi"
USER="root"
PASSWORD="mysqlrootpassword"
OUTPUT="/root/backup/dbserver"
 
rm "$OUTPUT/*gz" > /dev/null 2>&1
 
databases=`mysql --host=$DBHOST --user=$USER --password=$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
 
for dbitem in $databases; do
    if [[ "$dbitem" != "information_schema" ]] && [[ "$dbitem" != _* ]] ; then
        echo "Dumping database: $dbitem"
        mysqldump --force --opt --user=$USER --password=$PASSWORD --databases $dbitem > $OUTPUT/`date +%Y%m%d`.$dbitem.sql
        gzip $OUTPUT/`date +%Y%m%d`.$dbitem.sql
    fi
done

EOF

chmod +x dbserverbackup.sh
git add dbserverbackup.sh

cat <<'EOF' >s3backupscript.sh
#!/bin/bash
/root/backup/script/icinga2master_dbbackup.sh
/root/backup/script/dbserverbackup.sh
touch ~/old_perfdata.txt
cd /var/spool/icinga2/perfdata/ ; ls  -d -1 $PWD/{*,*} > ~/new_perfdata.txt
grep -v -F -x -f ~/old_perfdata.txt ~/new_perfdata.txt > ~/action_perfdata.txt
#cat ~/action_perfdata.txt | xargs -I % aws s3 cp s3://mioemi2000/
cd ~
mkdir copytest
cat ~/action_perfdata.txt | xargs -I % aws s3 cp ~/copytest/
mv ~/new_perfdata.txt ~/old_perfdata.txt
aws s3 cp -r /root/backup/  s3://mioemi2000/


EOF
chmod +x s3backupscript.sh
git add s3backupscript.sh
git commit -am "Project update"

}


while true; do
    read -p "Do you wish to install this program?" yn #AWSAccessKeyId, AWSSecretKey
    case $yn in
#        [Yy]* ) make install; break;;

 [Yy]* ) echo -n "Please provide your AWSAccessKeyId > "
read AWSAccessKeyId
echo -n "Please provide your AWSSecretKey > "
read AWSSecretKey
echo "Your AWSAccessKeyId: $AWSAccessKeyId"; 
echo "Your AWSSecretKey: $AWSSecretKey"; 
deploy;
break;;
       
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

 

#crontab -e
#0 19 * * * aws s3 ~/S3_backupscript
#The above cron job will run the command everyday at 7pm

