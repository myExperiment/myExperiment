#!/bin/bash

echo ""
echo "+----------------------------------------------------------------------------------------------+"
echo "|                  Welcome to the myExperimemt Installer for Ubuntu 10.04!                     |"
echo "|  Go to http://wiki.myexperiment.org/index.php/Developer:UbuntuInstallation for more details. |"
echo "+----------------------------------------------------------------------------------------------+"
echo ""

settings_file=`dirname $0`/settings.bash 
source ${settings_file} || { echo "Could not find settings file at ${settings_file}. Aborting ..."; exit 1; }

echo "Preseeding debconf"
sudo su -c "echo mysql-server-5.1 mysql-server/root_password password `echo "'"``echo ${mysql_root_password}``echo "'"` | debconf-set-selections" || { echo "Could not set debconf option mysql-server-5.1 mysql-server/root_password. Aborting ..."; exit 2; }
sudo su -c "echo mysql-server-5.1 mysql-server/root_password_again password `echo "'"``echo ${mysql_root_password}``echo "'"` | debconf-set-selections" || { echo "Could not set debconf option mysql-server-5.1 mysql-server/root_password_again. Aborting ..."; exit 3; }

echo "Installing required APT packages"
sudo apt-get update || { echo "Could not update apt-get. Aborting ..."; exit 4; }
sudo -n apt-get install -y build-essential exim4 ruby ruby1.8-dev libzlib-ruby rdoc irb rubygems rake apache2 apache2-dev libapache2-mod-fcgid libfcgi-ruby1.8 libmysql-ruby gcj-4.4-jre-headless subversion libopenssl-ruby1.8 libcurl3 libcurl3-gnutls libcurl4-openssl-dev mysql-server graphicsmagick imagemagick librmagick-ruby1.8 libmagick9-dev graphviz mlocate || { echo "Could not install required APT packages. Aborting ..."; exit 5; }

echo "Installing Rake version ${rake_version} and Rails version ${rails_version} Ruby Gems"
sudo gem install rake ${nordoc} ${nori} --version ${rake_version} || { echo "Could not install Rake Ruby Gem (version ${rake_version}). Aborting ..."; exit 6; }
sudo gem install rails ${nordoc} ${nori} --version ${rails_version} || { echo "Could not install Rails Ruby Gem (v${rails_version}) and dependencies. Aborting ..."; exit 7; }

echo "Installing Ruby Gems required by myExperiment"
if [ `cat /etc/environment | grep "/var/lib/gems/1.8/bin" | wc -l` -eq 0 ]; then
	cat /etc/environment | sed "s/\"$/:\/var\/lib\/gems\/1.8\/bin\"/" | sudo tee /etc/environment > /dev/null || { echo "Could not add Gems path to PATH.  Aborting ..."; exit 8;}
fi
if [ `echo ${PATH} | grep "/var/lib/gems/1.8/bin" | wc -l` -eq 0 ]; then
	DOLLAR='$'; echo -e "export PATH=${DOLLAR}PATH:/var/lib/gems/1.8/bin\nalias sudo='sudo env PATH=${DOLLAR}PATH'" >> /home/${USER}/.bashrc || { echo "Could not write to /home/${USER}/.bashrc.  Aborting ..."; exit 9;}
	source /home/${USER}/.bashrc || { echo "Could not source /home/${USER}/.bashrc.  Aborting ..."; exit 10; }
fi
sudo gem install ${nordoc} ${nori} mongrel_cluster rubyzip libxml-ruby rmagick dsl_accessor ruby-openid openurl curb marc || { echo "Could not install all remaining generic Ruby Gems required by myExperiment. Aborting ..."; exit 11; }

echo "Patching bug in Ubuntu 10.04 version of Ruby 1.8.7"
tempdir=$(mktemp -d /tmp/myexp_installer.XXXXXXXXXX) || { echo "Could not create temporary file for writing patches to. Aborting ..."; exit 12; }
cd ${tempdir} || { echo "Could not find temporary directory. Aborting ..."; exit 13; }
echo "${net_http_patch}" > net_http.patch || { echo "Could not write net/http patch file. Aborting ..."; exit 14; }

echo "Patching settings file to provide minimal configuration"
echo "${settings_patch}" > settings.patch || { echo "Could not write settings patch file. Aborting ..."; exit 15; }
sudo updatedb || { echo "Could not run updatedb so that http.rb that needs updating can be located. Aborting ..."; exit 16; }
net_http_file=`locate net/http.rb`
if [ ! -e ${net_http_file} ]; then
        echo "Could not locate net/http Ruby file that requires updating. Aborting ..."; exit 17;
fi
sudo patch ${net_http_file} ${tempdir}/net_http.patch || { echo "Could not patch net/http Ruby file: ${net_http_file}. Aborting ..."; exit 18; }

echo "Checking out myExperiment codebase from SVN"
cd /
for idir in `echo ${install_dir} | awk 'BEGIN{RS="/"}{print $1}'`; do
	if [ -n ${idir} ]; then
		if  [ ! -d ${idir} ]; then
			sudo mkdir ${idir} || { echo "Could not create directory ${idir} in `pwd`.  Aborting ..."; exit 19; }
		fi
		cd ${idir}
	fi
done
sudo chown ${USER}:www-data ${install_dir} || { echo "Could not update permissions on ${install_dir}. Aborting ..."; exit 20; }
svn checkout svn://rubyforge.org/var/svn/myexperiment/${branch} ${install_dir} || { echo "Could not checkout SVN to ${install_dir}. Aborting ..."; exit 21; }
cd ${install_dir}/config/ || { echo "Could not find config directory for myExperiment. Aborting ..."; exit 22; }

echo "Setting up config files for myExperiment"
cat database.yml.pre | sed "s/username: root/username: ${mysql_user_name}/" | sed "s/password:/password: ${mysql_user_password}/" > database.yml || { echo "Could not create database.yml file with appropriate configuration settings. Aborting ..."; exit 23; }
cp default_settings.yml settings.yml || { echo "Could not copy default_settings.yml to settings.yml ..."; exit 24; }
patch settings.yml ${tempdir}/settings.patch  || { echo "Could not patch settings.yml. Aborting ..."; exit 25; }
cp captcha.yml.pre captcha.yml || { echo "Could not create captcha.yml file.  Aborting ..."; exit 26; }
cd ..

echo "Setting up exim (Email) for myExperiment"
echo "${exim_config}" | sudo tee /etc/exim4/update-exim4.conf.conf > /dev/null  || { echo "Could not write new exim4 config.  Aborting..."; exit 27; }
echo "${fq_server_name}" | sudo tee /etc/mailname > /dev/null  || { echo "Could not update hostname for /etc/mailname.  Aborting..."; exit 28; }
sudo dpkg-reconfigure -fnoninteractive exim4-config || { echo "Could not write new reconfingure exim4.  Aborting..."; exit 29; }

echo "Setting up myExperiment databases in MySQL"
mysql -u root -p${mysql_root_password} -e "CREATE USER '${mysql_user_name}'@'localhost' IDENTIFIED BY '${mysql_user_password}'; CREATE DATABASE m2_development; CREATE DATABASE m2_production; CREATE DATABASE m2_test; GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,INDEX,ALTER,DROP,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW ON m2_development . * TO '${mysql_user_name}'@'localhost';GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,INDEX,ALTER,DROP,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW ON m2_production . * TO '${mysql_user_name}'@'localhost';GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,INDEX,ALTER,DROP,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW ON m2_test . * TO '${mysql_user_name}'@'localhost';" || { echo "Could not create myExperiment databases in MySQL and set up appropriate access for the ${mysql_user_name} user. Aborting ..."; exit 30; }

echo "Migrating myExperiment database"
rake db:migrate || { echo "Could not migrate myExperiment data model to a MySQL database. Aborting ..."; exit 31; }

echo "Starting Solr (search) server and indexing"
rake solr:start || { echo "Could not start Solr server. Aborting ..."; exit 32; }

echo "Installing and configuring Passenger Gem (mod_rails)";
sudo gem install passenger --version ${passenger_version} || { echo "Could not install Passnger Gem version ${passenger_version}. Aborting ..."; exit 33; }
sudo su -c "yes | /var/lib/gems/1.8/bin/passenger-install-apache2-module" || { echo "Could not install Apache2 module for Passenger. Aborting ..."; exit 34; }
echo "${apache_config}" | sudo tee /etc/apache2/sites-available/myexperiment > /dev/null || { echo "Could not add bespoke myExperiment Apache configuration. Aborting ..."; exit 35; }
if [ ! -h /etc/apache2/sites-enabled/myexperiment ]; then
	sudo ln -s /etc/apache2/sites-available/myexperiment /etc/apache2/sites-enabled/myexperiment || { echo "Could symlink Apache configuration to sites-enabled."; exit 36; }
fi
if [ -f "/etc/apache2/sites-enabled/000-default" ]; then
	sudo rm /etc/apache2/sites-enabled/000-default  || { echo "Could not remove 000-default to sites-enabled. Aborting ..."; exit 37; }
fi
sudo apache2ctl stop || { echo "Could not stop Apache2. Aborting ..."; exit 38; }
sleep 2
sudo apache2ctl start || { echo "Could not start Apache2. Aborting ..."; exit 39; }

echo "Removing temporary directory created for writing patch files to"
sudo rm -rf ${tempdir} || { echo "Could not remove temporary directory used by patch files."; exit 40; }

echo ""
echo "+-----------------------------------------------------------------------------------------+"
echo "|   myExperiment is now fully installed. Go to http://$myexp_cname/ to use myExperiment   |"
echo "+-----------------------------------------------------------------------------------------+"
