#!/bin/bash
echo ""
echo "+----------------------------------------------------------------------------------------------+"
echo "|        Welcome to the myExperimemt Installer for Fedora 13 / Red Hat 6 / CentOS 6.0!         |"
echo "| Go to http://wiki.myexperiment.org/index.php/Developer:FedoraInstallation for more details.  |"
echo "+----------------------------------------------------------------------------------------------+"
echo ""

d=`dirname $0`
basedir=`cd ${d}; pwd`
source ${basedir}/settings.bash || { echo "Could not find settings file at $settings_file. Aborting ..."; exit 1;}

echo "Extending timeout for sudo commands in /etc/sudoers.d/default_timeout"
echo "Defaults     timestamp_timeout = 3600" | sudo tee -a /etc/sudoers.d/default_timeout > /dev/null || { echo "Failed to disable sudo prompt timeout. Aborting ..."; exit 2; }
sudo chmod 440 /etc/sudoers.d/default_timeout || { echo "Failed to chmod /etc/sudoers.d/default_timeout. Aborting ..."; exit 70; }

echo "Installing required Yum packages"
sudo yum update || { echo "Failed to update apt-get. Aborting ..."; exit 3; }
sudo -n yum install -y subversion make patch gcc glibc-devel gcc-c++ ruby ruby-devel rdoc irb rubygems httpd httpd-devel mysql mysql-devel mysql-server ruby-mysql java subversion mlocate libxml2-devel libcurl-devel ImageMagick-devel ruby-RMagick graphviz sendmail sendmail-cf policycoreutils-python || { echo "Failed to install required Yum packages. Aborting ..."; exit 4; }

echo "Writing patch files to temporary directory"
tempdir=$(mktemp -d /tmp/myexp_installer.XXXXXXXXXX) || { echo "Could not create temporary file for writing patches to. Aborting ..."; exit 5; }
cd $tempdir || { echo "Could not find temporary directory. Aborting ..."; exit 6; }
echo "$sendmail_patch" > sendmail.patch || { echo "Could not write sendmail config patch file. Aborting ... "; exit 7; } 
echo "$settings_patch" > settings.patch || { echo "Could not write settings patch file. Aborting ..."; exit 8; }

echo "Configuring Apache, MySQL and Sendmail"
sudo chkconfig httpd on || { echo "Failed to Apache to applications started at boottime. Aborting ..."; exit 9; }
sudo chkconfig mysqld on || { echo "Failed to MySQL to applications started at boottime. Aborting ..."; exit 10; }
sudo chkconfig sendmail on || { echo "Failed to MySQL to applications started at boottime. Aborting ..."; exit 11; }
sudo cp /etc/hosts ${tempdir}/ || { echo "Failed to copy hosts file to ${tempdir}. Aborting ..."; exit 12; }
cat ${tempdir}/hosts | sed "s/localhost /localhost $myexp_cname /g" | sudo tee /etc/hosts >/dev/null || { echo "Failed to add myExperiment CName to /etc/hosts. Aborting ..."; exit 13; }
sudo service mysqld start || { echo "Failed to to start MySQL. Aborting ..."; exit 14; }
sudo patch /etc/mail/sendmail.mc  $tempdir/sendmail.patch || { echo "Could not patch sendmail.mc. Aborting ..."; exit 15; }
sudo m4 /etc/mail/sendmail.mc | sudo tee /etc/mail/sendmail.cf >/dev/null || { echo "Could not write sendmail config to sendmail.cf. Aborting ..."; exit 16; }
sudo setsebool -P httpd_can_sendmail=1 || { echo "Could not write set httpd_can_sendmail=1. Aborting ..."; exit 17; }
sudo service sendmail start || { echo "Failed to to start Sendmail. Aborting ..."; exit 18; }

echo "Installing Rake version $rake_version and Rails version $rails_version Ruby Gems"
sudo gem install $nordoc $nori rake --version $rake_version || { echo "Could not install Rake Ruby Gem (version $rake_version). Aborting ..."; exit 19; }
sudo gem install $nordoc $nori rails --version $rails_version || { echo "Failed to install Rails Ruby Gem (v$rails_version) and dependencies. Aborting ..."; exit 20; }

echo "Installing Ruby Gems required by myExperiment"
sudo gem install ${nordoc} ${nori} rubyzip --version 0.9.4 || { echo "Could not install rubyzip (v0.9.4). Aborting ..."; exit 21; }
sudo gem install ${nordoc} ${nori} libxml-ruby rmagick dsl_accessor ruby-openid openurl ruby-hmac marc || { echo "Could not install all remaining generic Ruby Gems required by myExperiment. Aborting ..."; exit 22; }
sudo gem install ${nordoc} ${nori} curb --version 0.7.15 || { echo "Could not install rubyzip (v0.7.15).. Aborting ..."; exit 23; }

echo "Checking out myExperiment codebase from SVN"
cd /
for idir in `echo ${install_dir} | awk 'BEGIN{RS="/"}{print $1}'`; do
        if [ -n ${idir} ]; then
                if  [ ! -d ${idir} ]; then
                        sudo mkdir ${idir} || { echo "Could not create directory ${idir} in `pwd`.  Aborting ..."; exit 24; }
                fi
                cd ${idir}
        fi
done
sudo chown $USER:apache $install_dir || { echo "Could not update permissions on $install_dir. Aborting ..."; exit 25; }
svn checkout svn://rubyforge.org/var/svn/myexperiment/$branch $install_dir || { echo "Could not checkout SVN to $install_dir. Aborting ..."; exit 26; }
cd ${install_dir}/config/ || { echo "Could not find config directory for myExperiment. Aborting ..."; exit 27; }

echo "Setting up config files for myExperiment"
cat database.yml.pre | sed "s/username: root/username: $mysql_user_name/" | sed "s/password:/password: $mysql_user_password/" > database.yml || { echo "Could not create database.yml file with appropriate configuration settings. Aborting ..."; exit 28; }
cp default_settings.yml settings.yml || { echo "Could not copy default_settings.yml to settings.yml ..."; exit 29; }
patch settings.yml $tempdir/settings.patch || { echo "Could not patch settings.yml. Aborting ..."; exit 30; }
cp captcha.yml.pre captcha.yml || { echo "Could not create captcha.yml file.  Aborting ..."; exit 31; }
cd ..

echo "Setting up myExperiment databases in MySQL"
sudo mysqladmin -u root password $mysql_root_password || { echo "Could not set MySQL root password. Assuming this is already set."; }
mysql -u root -p$mysql_root_password -e "CREATE USER '$mysql_user_name'@'localhost' IDENTIFIED BY '$mysql_user_password'; CREATE DATABASE m2_development; CREATE DATABASE m2_production; CREATE DATABASE m2_test; GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,INDEX,ALTER,DROP,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW ON m2_development . * TO '$mysql_user_name'@'localhost';GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,INDEX,ALTER,DROP,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW ON m2_production . * TO '$mysql_user_name'@'localhost';GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,INDEX,ALTER,DROP,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW ON m2_test . * TO '$mysql_user_name'@'localhost';" || { echo "Could not create myExperiment databases in MySQL and set up appropriate access for the $mysql_user_name user. Aborting ..."; exit 32; }

echo "Migrating myExperiment database"
rake db:migrate || { echo "Could not migrate myExperiment data model to a MySQL database. Aborting ..."; exit 33; }

echo "Starting Solr (search) server and indexing"
rake solr:start || { echo "Could not start Solr server. Aborting ..."; exit 34; }

echo "Adding Firewall rules for mongrel webserver on IPv4 and IPv6"
sudo chkconfig iptables on || { echo "Failed to iptables to applications started at boottime. Aborting ..."; exit 35; }
sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited || { echo "Could not delete rule from iptables. Aborting ..."; exit 36; }
sudo iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT || { echo "Could not add rule from iptables. Aborting ..."; exit 37; }
sudo iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25 -j ACCEPT || { echo "Could not add rule from iptables. Aborting ..."; exit 38; }
sudo iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited  || { echo "Could not add rule from iptables. Aborting ..."; exit 39; }
sudo iptables-save | sudo tee /etc/sysconfig/iptables >/dev/null  || { echo "Could not save new iptables rules. Aborting ..."; exit 40; }
sudo restorecon -v /etc/sysconfig/iptables || { echo "Could not restorecon for /etc/sysconfig/iptables. Aborting ..."; exit 41; }
sudo service iptables restart || { echo "Could not restart iptables. Aborting ..."; exit 42; }

sudo chkconfig ip6tables on || { echo "Failed to ip6tables to applications started at boottime. Aborting ..."; exit 43; }
sudo ip6tables -D INPUT -j REJECT --reject-with icmp6-adm-prohibited || { echo "Could not delete rule from ip6tables. Aborting ..."; exit 44; }
sudo ip6tables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT || { echo "Could not add rule from ip6tables. Aborting ..."; exit 45; }
sudo ip6tables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25 -j ACCEPT || { echo "Could not add rule from ip6tables. Aborting ..."; exit 46; }
sudo ip6tables -A INPUT -j REJECT --reject-with icmp6-adm-prohibited || { echo "Could not delete rule from ip6tables. Aborting ..."; exit 47; }
sudo ip6tables-save | sudo tee /etc/sysconfig/ip6tables >/dev/null || { echo "Could not save new ip6tables rules. Aborting ..."; exit 48; }
sudo restorecon -v /etc/sysconfig/ip6tables || { echo "Could not restorecon for /etc/sysconfig/ip6tables. Aborting ..."; exit 49; }
sudo service ip6tables restart || { echo "Could not restart ip6tables. Aborting ..."; exit 50; }

echo "Installing and configuring Passenger Gem (mod_rails)";
sudo gem install passenger --version ${passenger_version} || { echo "Could not install Passnger Gem version ${passenger_version}. Aborting ..."; exit 51; }
sudo su -c "yes | /usr/lib/ruby/gems/1.8/gems/passenger-2.2.15/bin/passenger-install-apache2-module" || { echo "Could not install Apache2 module for Passenger. Aborting ..."; exit 52; }
echo "${apache_config}" | sudo tee /etc/httpd/conf.d/myexp.conf > /dev/null || { echo "Could not add bespoke myExperiment Apache configuration. Aborting ..."; exit 53; }
sudo chmod -R 755 ${install_dir}/public || { echo "Failed to chmod ${install_dir}/public and its files/subdirectories. Aborting ..."; exit 54; }
sudo chmod 755 ${install_dir} || { echo "Failed to chmod ${install_dir}. Aborting ..."; exit 55; }
sudo chcon -t httpd_sys_script_exec_t -R ${install_dir} || { echo "Failed to chcon (httpd_sys_script_exec_t) ${install_dir} and its files/subdirectories. Aborting ..."; exit 56; }
sudo chcon -t httpd_sys_content_t -R ${install_dir}/public || { echo "Failed to chcon (httpd_sys_content_t) ${install_dir}/public and its files/subdirectories. Aborting ..."; exit 57; }
sudo chcon -t httpd_log_t -R ${install_dir}/log || { echo "Failed to chcon (httpd_log_t) ${install_dir}/log and its files. Aborting ..."; exit 58; }
sudo chcon -t httpd_tmpfs_t -R  ${install_dir}/tmp || { echo "Failed to chcon (httpd_tmpfs_t) ${install_dir}/tmp and its files. Aborting ..."; exit 59; }
sudo setsebool -P httpd_can_network_connect=1 || { echo "Could not write set httpd_can_network_connect=1. Aborting ..."; exit 60; }
sudo setenforce 0 || { echo "Could not temporarily setenforce = 0. Aborting ..."; exit 61; }
sudo service httpd start || { echo "Could not start Apache. Aborting ..."; exit 62; }
sudo grep httpd /var/log/audit/audit.log | audit2allow -M passenger || { echo "Could not create policy package passenger.pp. Aborting ..."; exit 63; }
sudo semodule -i passenger.pp || { echo "Could not add policy package passenger.pp using semodule. Aborting ..."; exit 64; }
sudo rm passenger.pp passenger.te || { echo "Could not remove files creates by audit2allow. Aborting ..."; exit 65; }
sudo setenforce 1 || { echo "Could not temporarily setenforce = 1. Aborting ..."; exit 66; }
sudo service httpd restart || { echo "Could not restart Apache. Aborting ..."; exit 67; }

echo "Removing extended sudo timeout from /etc/sudoers"
sudo rm /etc/sudoers.d/default_timeout || { echo "Could not remove extended timeout for sudo.  Aborting ..."; exit 68; }

echo "Removing temporary directory created for writing patch files to"
sudo rm -rf ${tempdir} || { echo "Could not remove temporary directory used by patch files."; exit 69; }

echo ""
echo "+-----------------------------------------------------------------------------------------+"
echo "|   myExperiment is now fully installed. Go to http://$myexp_cname/ to use myExperiment   |"
echo "+-----------------------------------------------------------------------------------------+"

