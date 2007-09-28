#!/bin/bash

export RAILS_ENV=production

RAILS_ROOT=/var/www/m2b
DB_USER=root
DB=m2_${RAILS_ENV}
DUMP_SRC=~/myexperiment/backup/myexperiment_production.sql
WORKFLOW_SRC=~/myexperiment/backup/workflow
SCUFL_SRC=${WORKFLOW_SRC}/scufl

if [ ! -e $DUMP_SRC ]; then
  echo SQL dump not found: $DUMP_SRC
  exit
fi

if [ ! -e $WORKFLOW_SRC ]; then
  echo Workflow directory not found: $WORKFLOW_SRC
  exit
fi

cd ${RAILS_ROOT}

rm -rf index carlin
mkdir carlin

cd carlin

rm -rf public/pictures
rm -rf public/workflow
cp ${DUMP_SRC} myexperiment_production.sql
cp -r ${SCUFL_SRC} scufl

grep 'INSERT INTO `pictures`'       < ${DUMP_SRC} >  import.sql
grep 'INSERT INTO `posts`'          < ${DUMP_SRC} >> import.sql
grep 'INSERT INTO `topics`'         < ${DUMP_SRC} >> import.sql

grep -v 'INSERT INTO `boards`' < myexperiment_production.sql > temp2.sql
grep -v 'INSERT INTO `channelmessages`'    < temp2.sql > temp3.sql
grep -v 'INSERT INTO `channels`'    < temp3.sql > temp4.sql
grep -v 'INSERT INTO `channels_users`'    < temp4.sql > temp5.sql
grep -v 'INSERT INTO `channel_topics`'    < temp5.sql > temp6.sql
grep -v 'INSERT INTO `experiments`'    < temp6.sql > temp7.sql
grep -v 'INSERT INTO `lists`'    < temp7.sql > temp8.sql
grep -v 'INSERT INTO `plugin_schema_info`'    < temp8.sql > temp9.sql
grep -v 'INSERT INTO `pictures`'    < temp9.sql > temp10.sql
grep -v 'INSERT INTO `posts`'    < temp10.sql > temp11.sql
grep -v 'INSERT INTO `replies`'    < temp11.sql > temp12.sql
grep -v 'INSERT INTO `schema_info`'    < temp12.sql > temp13.sql
grep -v 'INSERT INTO `todos`'    < temp13.sql > temp14.sql
grep -v 'INSERT INTO `topics`'    < temp14.sql > myexperiment_production.sql

mysql --user=${DB_USER} -e "drop database ${DB}"
mysql --user=${DB_USER} -e "create database ${DB}"
rake db:migrate
mysql --user=${DB_USER} ${DB} < import.sql

cd ${RAILS_ROOT}

echo 'include Squirrel; Squirrel.go false, true' | ruby script/console

