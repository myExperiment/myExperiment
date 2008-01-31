#!/bin/bash

RAILS_ROOT="/var/www/m2"
DB="m2_production"
DIRS="public/pictures public/workflow"
USER="backup"
BACKUP_DIR="/home/backup"

SQL_DUMP="${BACKUP_DIR}/myexp-$(date +%Y-%m-%d).sql"
PUB_DUMP="${BACKUP_DIR}/myexp-$(date +%Y-%m-%d).tgz"
SQL_LINK="${BACKUP_DIR}/myexp.sql"
PUB_LINK="${BACKUP_DIR}/myexp.tgz"

/usr/bin/mysqldump ${DB} > ${SQL_DUMP}
/bin/tar Cczf ${RAILS_ROOT} ${PUB_DUMP} ${DIRS}
/bin/ln -sf ${SQL_DUMP} ${SQL_LINK}
/bin/ln -sf ${PUB_DUMP} ${PUB_LINK}
/bin/chown -h ${USER}:${USER} ${SQL_DUMP} ${PUB_DUMP} ${SQL_LINK} ${PUB_LINK}
