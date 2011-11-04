#!/bin/bash
install_dir="/var/rails/myexperiment" # Where to checkout the myExperiment SVN
mysql_root_password="changme"
mysql_user_name="myexp"
mysql_user_password="changeme"
rdoc=1 # Set to 0 if you want no RDoc Ruby Gem documentaion
ri=1 # Set yo 0 if you want no RI Ruby Gem documentatiom
rake_version="0.7.2" 
rails_version="1.2.6"
fq_server_name="server.domain"
exim_smarthost="smtp.domain"

# Patch Files
oauth_patch='--- action_controller_request.rb.old    2011-10-26 15:52:34.250151798 +0000
+++ action_controller_request.rb        2011-10-26 15:50:59.937490274 +0000
@@ -55,7 +55,13 @@
     end

     def request_params
-      request.request_parameters
+      unless @request_parameters
+        @request_parameters = request.request_parameters.dup
+        request.symbolized_path_parameters.keys.each do |k|
+          @request_parameters.delete k.to_s
+        end if request.respond_to? :symbolized_path_parameters
+      end
+      @request_parameters
     end

   end
'
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
settings_patch='--- default_settings.yml        2011-10-26 06:32:16.344994469 +0100
+++ settings.yml        2011-10-26 06:38:39.788127578 +0100
@@ -302,19 +302,16 @@
 # solr_enable - Set solr_enable to true to enable the search facility - this
 #               requires a running solr server.

-solr_enable: false
+solr_enable: true

 # smtp - Email configuration.  These details are used to connect to a SMTP
 #        server instead of sendmail.

 smtp:

-  :address:        "smtp.example.com"
+  :address:        "relay.ecs.soton.ac.uk"
   :port:           25,
-  :domain:         ""
-  :authentication: :login
-  :user_name:      "username"
-  :password:       "password"
+  :domain:         "ecs.soton.ac.uk"

 # show_debug - Shows query statistics in the footer: "Queries in Controller",
 #              "Queries in View" and "Query Time".
'

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

