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


