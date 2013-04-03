#!/bin/bash

echo ""
echo "+----------------------------------------------------------------------------------------------+"
echo "|           Welcome to the myExperiment Installer for Ubuntu 10.04 LTS / 12.04 LTS             |"
echo "|  Go to http://wiki.myexperiment.org/index.php/Developer:UbuntuInstallation for more details. |"
echo "+----------------------------------------------------------------------------------------------+"
echo ""

d=`dirname $0`
basedir=`cd ${d}; pwd`
settings_file="${basedir}/settings.bash "
source ${settings_file} || { echo "Could not find settings file at ${settings_file}. Aborting ..."; exit 1; }

echo "Creating temporary directory for installation files"
tempdir=$(mktemp -d /tmp/myexp_installer.XXXXXXXXXX) || { echo "Could not create temporary file for writing patches to. Aborting ..."; exit 2; }

echo "Preseeding debconf"
sudo su -c "echo mysql-server-5.1 mysql-server/root_password password `echo "'"``echo ${mysql_root_password}``echo "'"` | debconf-set-selections" || { echo "Could not set debconf option mysql-server-5.1 mysql-server/root_password. Aborting ..."; exit 3; }
sudo su -c "echo mysql-server-5.1 mysql-server/root_password_again password `echo "'"``echo ${mysql_root_password}``echo "'"` | debconf-set-selections" || { echo "Could not set debconf option mysql-server-5.1 mysql-server/root_password_again. Aborting ..."; exit 4; }

source "${basedir}/dependencies.bash"

echo "Installing and configuring RVM"
sudo bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer ) || { echo "Could not install RVM. Aborting ..."; exit 7; }
echo '[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"' >> ~/.bashrc || { echo "Could not add RVM loading to $HOME/.bashrc. Aborting ..."; exit 8; }

echo "Install and configuring Ruby version ${ruby_version}"
source "/usr/local/rvm/scripts/rvm" || { echo "Could not source /usr/local/rvm/scripts/rvm to add RVM directory to path. Aborting ..."; exit 9; }
rvmsudo rvm install ${ruby_version}  || { echo "Could not install Ruby ${ruby_version} using RVM. Aborting ..."; exit 10; }
rvm --default use ${ruby_version} || { echo "Could not set Ruby ${ruby_version} as the default environment for RVM. Aborting ..."; exit 11; }

echo "Checking out myExperiment codebase from SVN"
sudo mkdir -p ${install_dir} || { echo "Could not create directory ${install_dir} or one of its parent directories. Aborting ..."; exit 12; }
sudo chown ${USER}:${USER} ${install_dir} || { echo "Could not update permissions on ${install_dir}. Aborting ..."; exit 13; }
svn checkout svn://rubyforge.org/var/svn/myexperiment/${branch} ${install_dir} || { echo "Could not checkout SVN to ${install_dir}. Aborting ..."; exit 14; }
cd ${install_dir}/config/ || { echo "Could not find config directory for myExperiment. Aborting ..."; exit 15; }

echo "Setting up config files for myExperiment"
cat database.yml.pre | sed "s/password:/password: ${mysql_root_password}/" > database.yml || { echo "Could not create database.yml file with appropriate configuration settings. Aborting ..."; exit 16; }
cp default_settings.yml settings.yml || { echo "Could not copy default_settings.yml to settings.yml. Aborting ..."; exit 17; }
echo "${settings_patch}" > ${tempdir}/settings.patch || { echo "Could not write settings patch file. Aborting ..."; exit 18; }
patch settings.yml ${tempdir}/settings.patch  || { echo "Could not patch settings.yml. Aborting ..."; exit 19; }
cp captcha.yml.pre captcha.yml || { echo "Could not create captcha.yml file. Aborting ..."; exit 20; }

echo "Installing Gems required by myExperiment using bundler"
cd ${install_dir}
bundle install || { echo "Could not install the Gems required by myExperiment using bundler. Aborting ..."; exit 21; }

echo "Setting up exim (Email) for myExperiment"
echo "${exim_config}" > ${tempdir}/update-exim4.conf.conf || { echo "Could not write exim4 config to ${tempdir}/update-exim4.conf.conf. Aborting ..."; exit 22; }
sudo mv ${tempdir}/update-exim4.conf.conf /etc/exim4/ || { echo "Could not move new exim4 config to /etc/exim4/update-exim4.conf.conf. Aborting ..."; exit 23; }
echo "${fq_server_name}" > ${tempdir}/mailname || { echo "Could not write mailname (${fq_server_name}) to ${tempdir}/mailname. Aborting ..."; exit 24; }
sudo mv ${tempdir}/mailname /etc/ || { echo "Could not update hostname for /etc/mailname. Aborting ..."; exit 25; }
sudo dpkg-reconfigure -fnoninteractive exim4-config || { echo "Could not write new reconfingure exim4. Aborting ..."; exit 26; }

echo "Creating and migrating myExperiment database"
rake db:create:all || { echo "Could not create MySQL database for myExperiment data model. Aborting ..."; exit 27; }
rake db:migrate || { echo "Could not migrate myExperiment data model to a MySQL database. Aborting ..."; exit 28; }

echo "Creating myExperiment init.d script and deploying so myExperiment automatically starts after machine start up"
echo "${initd_script}" > ${tempdir}/myexperiment || { echo "Could not create myExperiment init.d script. Aborting ..."; exit 29; }
sudo mv ${tempdir}/myexperiment /etc/init.d || { echo "Could not move myExperiment init.d script to /etc/init.d. Aborting ..."; exit 30; }
sudo chown root:root /etc/init.d/myexperiment || { echo "Could not change ownwership of /etc/init.d/myexperiment. Aborting ..."; exit 31; }
sudo chmod +x /etc/init.d/myexperiment || { echo "Could not modify permissions of /etc/init.d/myexperiment. Aborting ..."; exit 32; }
sudo update-rc.d myexperiment defaults || { echo "Could not deploy /etc/init.d/myexperiment as a startup script. Aborting ..."; exit 33; }

sudo service myexperiment start || { echo "Could not start myExperiment. Aborting ..."; exit 34; }

echo "Tidying up"
rm -r ${tempdir} || { echo "Could not delete temporary directory ${tempdir}. Aborting ..."; exit 35; }

echo ""
echo "========================================================================================================"
echo " myExperiment is now fully installed. Go to http://${myexp_cname}:${myexp_port_no}/ to use myExperiment"
echo " To start, stop or restart myExperiment use: sudo service myexperiment start|stop|restart" 
echo "========================================================================================================"

