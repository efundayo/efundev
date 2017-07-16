#!/bin/bash
/root/backup/script/icinga2master_dbbackup.sh
/root/backup/script/dbserverbackup.sh
touch ~/old_perfdata.txt
cd /var/spool/icinga2/perfdata/ ; ls  -d -1 $PWD/{*,*} > ~/new_perfdata.txt
grep -v -F -x -f ~/old_perfdata.txt ~/new_perfdata.txt > ~/action_perfdata.txt
#cat ~/action_perfdata.txt | xargs -I % aws s3 cp s3://mioemi2000/
cd ~
mkdir copytest
cat ~/action_perfdata.txt | xargs -I %  cp ~/copytest/
mv ~/new_perfdata.txt ~/old_perfdata.txt
aws s3 cp -r /root/backup/  s3://mioemi2000/


