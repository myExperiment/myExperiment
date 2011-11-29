#!/bin/bash
install_dir="/var/rails/myexperiment" # Where to checkout the myExperiment SVN
branch="trunk"
mysql_root_password="changeme"
mysql_user_name="myexp"
mysql_user_password="changeme"
rdoc=1 # Set to 0 if you want no RDoc Ruby Gem documentaion
ri=1 # Set yo 0 if you want no RI Ruby Gem documentatiom
rake_version="0.8.7" 
rails_version="2.3.14"
passenger_version="2.2.15"
fq_server_name="server.domain"
exim_smarthost_server="smtp"
exim_smarthost_domain="domain"
myexp_cname="myexp.domain" # Where your myExperiment will be hosted can be the same as $fq_server_name


# Patch Files
net_http_patch='Index: lib/net/http.rb
===================================================================
--- lib/net/http.rb     (revision 26550)
+++ lib/net/http.rb     (working copy)
@@ -1057,7 +1057,7 @@
       res
     rescue => exception
       D "Conn close because of error #{exception}"
-      @socket.close unless @socket.closed?
+      @socket.close if @socket and not @socket.closed?
       raise exception
     end'

exim_smarthost="${exim_smarthost_server}.${exim_smarthost_domain}"
settings_patch='--- default_settings.yml	2011-11-28 18:40:40.337937711 +0000
+++ settings.yml	2011-11-28 19:00:56.231831591 +0000
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

apache_config="LoadModule passenger_module /var/lib/gems/1.8/gems/passenger-${passenger_version}/ext/apache2/mod_passenger.so
PassengerRoot /var/lib/gems/1.8/gems/passenger-${passenger_version}
PassengerRuby /usr/bin/ruby1.8
RailsEnv development

<VirtualHost *:80>
        ServerAdmin ${USER}@localhost
        ServerName ${myexp_cname}
        DocumentRoot ${install_dir}/public
        <Directory ${install_dir}/public/>
                AllowOverride all
                Options -MultiViews
        </Directory>
</VirtualHost>"


# Configure options for (Ruby) gem install
if [ ${rdoc} == 0 ]; then
        nordoc="--no-rdoc"
else
        nordoc=""
fi
if [ ${ri} == 0 ]; then
        nori="--no-ri"
else
        nori=""
fi

