#!/bin/bash

RAILS_ROOT=~/m2
DB_USER=root
DB=m2_development
DUMP_SRC=~/myexperiment/backup/myexperiment_production.sql 
SCUFL_SRC=~/myexperiment/backup/workflow/scufl

cd ${RAILS_ROOT}

rm -rf index carlin
mkdir carlin

cd carlin

rm -rf public/workflow
cp ${DUMP_SRC} .
cp -r ${SCUFL_SRC} .

grep 'INSERT INTO `pictures`'       < ${DUMP_SRC} >  import.sql
grep 'INSERT INTO `moderatorships`' < ${DUMP_SRC} >> import.sql
grep 'INSERT INTO `posts`'          < ${DUMP_SRC} >> import.sql
grep 'INSERT INTO `monitorships`'   < ${DUMP_SRC} >> import.sql
grep 'INSERT INTO `topics`'         < ${DUMP_SRC} >> import.sql

mysql --user=${DB_USER} -e "drop database ${DB}"
mysql --user=${DB_USER} -e "create database ${DB}"
rake db:migrate
mysql --user=${DB_USER} ${DB} < import.sql

cd ${RAILS_ROOT}

echo 'include Squirrel; Squirrel.go false, true' | ruby script/console

