#!/bin/bash
install_dir="/var/rails/myexperiment" # Where to checkout the myExperiment SVN
branch="trunk"
ruby_version="1.8.7"
mysql_root_password="changeme"
fq_server_name="server.domain"
myexp_cname="myexp.domain" # Where your myExperiment will be hosted can be the same as $fq_server_name
myexp_port_no="3000"
exim_smarthost_server="smtp"
exim_smarthost_domain="domain"
exim_smarthost="${exim_smarthost_server}.${exim_smarthost_domain}"

settings_patch='--- default_settings.yml     2011-11-28 18:40:40.337937711 +0000
+++ settings.yml     2011-11-28 19:00:56.231831591 +0000
@@ -75,7 +75,7 @@
 #
 #            NOTE: No trailing slash.
 
-base_uri: http://www.example.com
+base_uri: http://'${myexp_cname}':'$myexp_port_no'
 
 # admins - Set "admins" to the list of usernames of people that are
 #          administrators of this installation.  This is "Username" that is set
@@ -302,19 +302,16 @@
 # solr_enable - Set solr_enable to true to enable the search facility - this
 #               requires a running solr server.

-solr_enable: false
+solr_enable: true

 # smtp - Email configuration.  These details are used to connect to a SMTP
 #        server instead of sendmail.

 smtp:

-  :address:        "smtp.example.com"
+  :address:        "'${exim_smarthost}'"
   :port:           25,
-  :domain:         ""
-  :authentication: :login
-  :user_name:      "username"
-  :password:       "password"
+  :domain:         "'${exim_smarthost_domain}'"

 # show_debug - Shows query statistics in the footer: "Queries in Controller",
 #              "Queries in View" and "Query Time".
'

exim_config="dc_eximconfig_configtype='satellite'
dc_other_hostnames='${fq_server_name}'
dc_local_interfaces='127.0.0.1 ; ::1'
dc_readhost='${fq_server_name}'
dc_relay_domains=''
dc_minimaldns='false'
dc_relay_nets=''
dc_smarthost='${exim_smarthost}'
CFILEMODE='644'
dc_use_split_config='false'
dc_hide_mailname='true'
dc_mailname_in_oh='true'
dc_localdelivery='mail_spool'" 

initd_script='#!/bin/bash -e

### BEGIN INIT INFO
# Provides:          myexperiment
# Required-Start:    
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts, stops, and restarts myExperiment.
# Description:       Starts, stops, and restarts myExperiment.
### END INIT INFO

MYEXP_DIR="'${install_dir}'"
SOLR_LOG_FILE="'${install_dir}'/log/solr.log"
SOLR_ERR_FILE="'${install_dir}'/log/solr.err"
MYEXP_LOG_FILE="'${install_dir}'/log/myexperiment.log"
MYEXP_ERR_FILE="'${install_dir}'/log/myexperiment.err"
MYEXP_PID_FILE="'${install_dir}'/log/myexperiment.pid"

case $1 in
    start)
        echo "Starting myExperiment..."
        source /usr/local/rvm/scripts/rvm
        rvm --default use '${ruby_version}'
        cd $MYEXP_DIR || { exit 1; }
        rake solr:start 2>> $SOLR_ERR_FILE 1>> $SOLR_LOG_FILE
        ruby script/server 2>> $MYEXP_ERR_FILE 1>> $MYEXP_LOG_FILE &
        echo $! > $MYEXP_PID_FILE 
        echo "myExperiment started"
        ;;
    stop)
        echo "Stopping myExperiment..."
        source /usr/local/rvm/scripts/rvm
        rvm --default use '${ruby_version}'
        cd $MYEXP_DIR || { exit 1; }
        rake solr:stop 2>> $SOLR_ERR_FILE 1>> $SOLR_LOG_FILE 
        if [ -s $MYEXP_PID_FILE ]; then
            kill -9 `cat $MYEXP_PID_FILE` 
            rm $MYEXP_PID_FILE
        else 
            echo "$MYEXP_PID_FILE does not exist or is empty"
            if [ -f $MYEXP_PID_FILE ]; then
                rm $MYEXP_PID_FILE
            fi
            exit 2
        fi
        echo "myExperiment stopped"
        ;;
    restart)
        $0 stop
        sleep 3
        $0 start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}" >&2
        exit 1        
        ;;
esac'
