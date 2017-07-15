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
lab_gateway_public_hostname=ec2-52-10-69-127.us-west-2.compute.amazonaws.com
lab_gateway_public_ip=52.10.69.127
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


