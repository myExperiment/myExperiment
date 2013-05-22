#!/bin/bash
install_dir="/var/rails/myexperiment" # Where to checkout the myExperiment SVN
branch="trunk"
ruby_version="1.8.7"
mysql_root_password="changeme"
fq_server_name="hostname.domain"
myexp_cname="myexp.domain"
myexp_port_no="3000"
sendmail_smarthost_server="smtp"
sendmail_smarthost_domain="domain"
sendmail_smarthost="${sendmail_smarthost_server}.${sendmail_smarthost_domain}"

# Sendmail patch for relaying email
sendmail_patch="--- a/sendmail.mc       2011-10-25 12:50:51.320183676 +0100
+++ b/sendmail.mc       2011-12-19 18:36:21.538188432 +0000
@@ -23,7 +23,7 @@
 dnl # Uncomment and edit the following line if your outgoing mail needs to
 dnl # be sent out through an external mail server:
 dnl #
-dnl define(\`SMART_HOST', \`smtp.your.provider')dnl
+define(\`SMART_HOST', \`${sendmail_smarthost}')dnl
 dnl #
 define(\`confDEF_USER_ID', \`\`8:12'')dnl
 dnl define(\`confAUTO_REBUILD')dnl
@@ -171,6 +171,14 @@
 dnl MASQUERADE_DOMAIN(localhost.localdomain)dnl
 dnl MASQUERADE_DOMAIN(mydomainalias.com)dnl
 dnl MASQUERADE_DOMAIN(mydomain.lan)dnl
+FEATURE(always_add_domain)dnl
+FEATURE(\`masquerade_entire_domain')dnl
+FEATURE(\`masquerade_envelope')dnl
+FEATURE(\`allmasquerade')dnl
+MASQUERADE_AS(\`${sendmail_smarthost_domain}')dnl
+MASQUERADE_DOMAIN(\`${sendmail_smarthost_domain}')dnl
+MASQUERADE_AS(${sendmail_smarthost_domain})dnl
+dnl
 MAILER(smtp)dnl
 MAILER(procmail)dnl
 dnl MAILER(cyrusv2)dnl"

# myExperiment settings file patch
settings_patch='--- default_settings.yml        2011-11-28 18:40:40.337937711 +0000
+++ settings.yml        2011-11-28 19:00:56.231831591 +0000
@@ -75,7 +75,7 @@
 #
 #            NOTE: No trailing slash.
 
-base_uri: http://www.example.com
+base_uri: http://'${myexp_cname}':'${myexp_port_no}'
 
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
+  :address:        "'${sendmail_smarthost}'"
   :port:           25,
-  :domain:         ""
-  :authentication: :login
-  :user_name:      "username"
-  :password:       "password"
+  :domain:         "'${sendmail_smarthost_domain}'"

 # show_debug - Shows query statistics in the footer: "Queries in Controller",
 #              "Queries in View" and "Query Time".
'

# init.d script so myExperiment can be easily stopped/started
initd_script='#!/bin/bash -e
#
# myexperiment  Starts, stops, and restarts myExperiment
#
# chkconfig: - 64 36
# description:  MyExperiment web application
# processname: myexperiment

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
        ruby script/server -p '${myexp_port_no}' 2>> $MYEXP_ERR_FILE 1>> $MYEXP_LOG_FILE &
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

