#!/bin/bash
install_dir="/var/rails/myexperiment" # Where to check the myExperiment SVN
branch="trunk"
mysql_root_password="changeme"
mysql_user_name="myexp"
mysql_user_password="changeme"
rdoc=1 # Set to 0 for no RDoc Ruby Gem documentation
ri=1 # Set to 0 for no RI Ruby Gem documentation
rake_version="0.8.7"
rails_version="2.3.14"
passenger_version="2.2.15"
fq_server_name="hostname.domain"
sendmail_smarthost_server="smtp"
sendmail_smarthost_domain="domain"
myexp_cname="myexp.domain" # Where your myexperiment will be hosted can be the same as $fq_server_name

# Build fully-qualified server name for the smarthost (relay) to be used by Sendmail
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
+base_uri: http://'${myexp_cname}'
 
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

# Apache config for myExperiment
apache_config="LoadModule passenger_module /usr/lib/ruby/gems/1.8/gems/passenger-${passenger_version}/ext/apache2/mod_passenger.so
PassengerRoot /usr/lib/ruby/gems/1.8/gems/passenger-${passenger_version}
PassengerRuby /usr/bin/ruby
PassengerDefaultUser ${USER}
RailsEnv development

<VirtualHost *:80>
        ServerAdmin ${USER}@localhost
        ServerName ${myexp_cname}
        DocumentRoot ${install_dir}/public
	PassengerTempDir ${install_dir}/tmp
        <Directory ${install_dir}/public/>
                AllowOverride all
                Options -MultiViews
        </Directory>
</VirtualHost>"

# Configure options for (Ruby) gem install
if [ $rdoc == 0 ]; then
        nordoc="--no-rdoc"
else
        nordoc=""
fi
if [ $ri == 0 ]; then
        nori="--no-ri"
else
        nori=""
fi
