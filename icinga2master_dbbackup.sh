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

