#!/bin/bash

RAILS_ROOT=~/mark-branch
DB_USER=root
DB=m2_development
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

grep -v 'INSERT INTO `pictures`' < myexperiment_production.sql > temp2.sql
grep -v 'INSERT INTO `posts`'    < temp2.sql > temp3.sql
grep -v 'INSERT INTO `topic`'    < temp3.sql > myexperiment_production.sql

mysql --user=${DB_USER} -e "drop database ${DB}"
mysql --user=${DB_USER} -e "create database ${DB}"
rake db:migrate
mysql --user=${DB_USER} ${DB} < import.sql

cd ${RAILS_ROOT}

echo 'include Squirrel; Squirrel.go false, true' | ruby script/console

