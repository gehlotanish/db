#!/bin/bash

################################################################
##      CRON 0 0 * * * /bin/bash /backup/.backup.sh
##
################################################################

export PATH=/bin:/usr/bin:/usr/local/bin
TODAY=`date +%d_%m_%Y-%H`
BACKUP_RETAIN_DAYS="7"


DB_BACKUP_PATH='/usr/local/.db'
################################################################
################## Update below values  ########################

function setkey() {

if [ ! -d $DB_BACKUP_PATH  ]; then
       mkdir $DB_BACKUP_PATH
fi

read -p $'\e[1;92m[*] Enter Username: \e[0m' choice
echo $choice | base64 >> /usr/local/.db/.key

read -p $'\e[1;92m[*] Enter Password: \e[0m' choice
echo $choice | base64 >> /usr/local/.db/.key

read -p $'\e[1;92m[*] Enter Database: \e[0m' choice
echo $choice | base64 >> /usr/local/.db/.key

read -p $'\e[1;92m[Default localhost] Enter hostname: \e[0m' choice
if [ ! -z $choice ]; then
        echo $choice | base64 >> /usr/local/.db/.key
else
        echo "localhost" | base64 >> /usr/local/.db/.key
fi

read -p $'\e[1;92m[Default 3306] Enter Port: \e[0m' choice
if [ ! -z $choice ]; then
        echo $choice | base64 >> /usr/local/.db/.key
else
        echo "3306" | base64 >> /usr/local/.db/.key
fi

}

function  resetkey() {
        echo "" > /usr/local/.db/.key
        sed -i '1d' /usr/local/.db/.key
}

function backup() {

MYSQL_USER=`awk 'NR==1' /usr/local/.db/.key | base64 -d`
MYSQL_PASSWORD=`awk 'NR==2' /usr/local/.db/.key | base64 -d`
DATABASE_NAME=`awk 'NR==3' /usr/local/.db/.key | base64 -d`
MYSQL_HOST=`awk 'NR==4' /usr/local/.db/.key | base64 -d`
MYSQL_PORT=`awk 'NR==5' /usr/local/.db/.key | base64 -d`

##################################################################

mkdir -p ${DB_BACKUP_PATH}/${TODAY}

mysqldump -h ${MYSQL_HOST} \
   -P ${MYSQL_PORT} \
   -u ${MYSQL_USER} \
   --password=${MYSQL_PASSWORD} \
   ${DATABASE_NAME} | gzip > ${DB_BACKUP_PATH}/${TODAY}/${DATABASE_NAME}-${TODAY}.sql.gz

if [ $? -eq 0 ]; then
  echo "Database backup successfully completed"
else
  echo "Error found during backup"
  exit 1
fi

cd /var/www
zip -r html.${TODAY}.zip html
mv html.${TODAY}.zip ${DB_BACKUP_PATH}/${TODAY}/html_${TODAY}.zip

##### Remove backups older than {BACKUP_RETAIN_DAYS} days  #####

DBDELDATE=`date +"%d_%m_%Y-%H" --date="${BACKUP_RETAIN_DAYS} days ago"`

if [ ! -z ${DB_BACKUP_PATH} ]; then
      cd ${DB_BACKUP_PATH}
      if [ ! -z ${DBDELDATE} ] && [ -d ${DBDELDATE} ]; then
            rm -rf ${DBDELDATE}
      fi
fi

}

case $1 in

     -s)
            setkey
            ;;
     -r)
            resetkey
            ;;
     *)
            backup
esac
