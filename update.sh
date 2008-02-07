#!/bin/bash

LOG=log/update.log

echo >> ${LOG} ------------------------------------------------------------
date >> ${LOG}
echo >> ${LOG} ------------------------------------------------------------
echo >> ${LOG}

/etc/init.d/myexperiment stop  | tee -a ${LOG}

echo >> ${LOG}

svn update                     | tee -a ${LOG}

echo >> ${LOG}

rake db:migrate                | tee -a ${LOG}

echo >> ${LOG}

/etc/init.d/myexperiment start | tee -a ${LOG}

echo >> ${LOG}

