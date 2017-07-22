#!/bin/bash
/root/backup/script/icinga2master_dbbackup.sh
/root/backup/script/dbserverbackup.sh
aws s3 sync /var/spool/icinga2/perfdata/ s3://mioemi2000/perfdata

aws s3 cp -r /root/backup/  s3://mioemi2000/db_backup

