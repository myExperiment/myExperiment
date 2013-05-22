#!/bin/bash
echo ""
echo "+----------------------------------------------------------------------------------------------+"
echo "|         Welcome to the myExperimemt Installer for Fedora 13 / RedHat 6 / CentOS 6.0!         |"
echo "| Go to http://wiki.myexperiment.org/index.php/Developer:FedoraInstallation for more details.  |"
echo "+----------------------------------------------------------------------------------------------+"
echo ""

d=`dirname $0`
basedir=`cd ${d}; pwd`
source ${basedir}/settings.bash || { echo "Could not find settings file at $settings_file. Aborting ..."; exit 1;}

echo "Creating temporary directory for installation files"
tempdir=$(mktemp -d /tmp/myexp_installer.XXXXXXXXXX) || { echo "Could not create temporary file for writing patches to. Aborting ..."; exit 2; }
cd $tempdir || { echo "Could not find temporary directory. Aborting ..."; exit 3; }
echo "$sendmail_patch" > sendmail.patch || { echo "Could not write sendmail config patch file. Aborting ... "; exit 4; }
echo "$settings_patch" > settings.patch || { echo "Could not write settings patch file. Aborting ..."; exit 5; }

echo "Installing required Yum packages"
sudo yum update -y || { echo "Failed to update apt-get. Aborting ..."; exit 6; }
sudo -n yum install -y subversion make patch gcc glibc-devel gcc-c++ mysql mysql-devel mysql-server java libxml2-devel libxslt-devel autoconf glibc-devel ncurses-devel automake libtool bison openssl openssl-devel curl libcurl libcurl-devel readline readline-devel ImageMagick-devel graphviz sendmail sendmail-cf policycoreutils-python || { echo "Failed to install required Yum packages. Aborting ..."; exit 7; }

echo "Configuring Apache, MySQL and Sendmail"
sudo chkconfig mysqld on || { echo "Failed to MySQL to applications started at boottime. Aborting ..."; exit 8; }
sudo chkconfig sendmail on || { echo "Failed to MySQL to applications started at boottime. Aborting ..."; exit 9; }
sudo cp /etc/hosts ${tempdir}/ || { echo "Failed to copy hosts file to ${tempdir}. Aborting ..."; exit 10; }
cat ${tempdir}/hosts | sed "s/localhost /localhost $myexp_cname /g" | sudo tee /etc/hosts >/dev/null || { echo "Failed to add myExperiment CName to /etc/hosts. Aborting ..."; exit 11; }
sudo service mysqld start || { echo "Failed to to start MySQL. Aborting ..."; exit 12; }
sudo patch /etc/mail/sendmail.mc  $tempdir/sendmail.patch || { echo "Could not patch sendmail.mc. Aborting ..."; exit 13; }
sudo m4 /etc/mail/sendmail.mc | sudo tee /etc/mail/sendmail.cf >/dev/null || { echo "Could not write sendmail config to sendmail.cf. Aborting ..."; exit 14; }
sudo setsebool -P httpd_can_sendmail=1 || { echo "Could not write set httpd_can_sendmail=1. Aborting ..."; exit 15; }
sudo service sendmail start || { echo "Failed to to start Sendmail. Aborting ..."; exit 16; }

echo "Installing and configuring RVM"
sudo bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer ) || { echo "Could not install RVM. Aborting ..."; exit 17; }

echo "Install and configuring Ruby version ${ruby_version}"
source "/usr/local/rvm/scripts/rvm" || { echo "Could not source /usr/local/rvm/scripts/rvm to add RVM directory to path. Aborting ..."; exit 18; }
rvmsudo rvm install ${ruby_version}  || { echo "Could not install Ruby ${ruby_version} using RVM. Aborting ..."; exit 19; }
rvm --default use ${ruby_version} || { echo "Could not set Ruby ${ruby_version} as the default environment for RVM. Aborting ..."; exit 20; }

echo "Checking out myExperiment codebase from SVN"
sudo mkdir -p ${install_dir} || { echo "Could not create directory ${install_dir} or one of its parent directories. Aborting ..."; exit 21; }
sudo chown ${USER}:${USER} ${install_dir} || { echo "Could not update permissions on ${install_dir}. Aborting ..."; exit 22; }
svn checkout svn://rubyforge.org/var/svn/myexperiment/$branch $install_dir || { echo "Could not checkout SVN to $install_dir. Aborting ..."; exit 24; }
cd ${install_dir}/config/ || { echo "Could not find config directory for myExperiment. Aborting ..."; exit 25; }

echo "Setting up config files for myExperiment"
cat database.yml.pre | sed "s/username: root/username: $mysql_user_name/" | sed "s/password:/password: $mysql_user_password/" > database.yml || { echo "Could not create database.yml file with appropriate configuration settings. Aborting ..."; exit 26; }
cp default_settings.yml settings.yml || { echo "Could not copy default_settings.yml to settings.yml ..."; exit 27; }
patch settings.yml $tempdir/settings.patch || { echo "Could not patch settings.yml. Aborting ..."; exit 28; }

echo "Installing Gems required by myExperiment using bundler"
cd ${install_dir}
bundle install || { echo "Could not install the Gems required by myExperiment using bundler. Aborting ..."; exit 30; }

echo "Creating and migrating myExperiment database"
rake db:create:all || { echo "Could not create MySQL databases for myExperiment. Aborting ..."; exit 31; }
rake db:migrate || { echo "Could not migrate myExperiment data model to a MySQL database. Aborting ..."; exit 32; }

echo "Creating myExperiment init.d script and deploying so myExperiment automatically starts after machine start up"
echo "${initd_script}" > ${tempdir}/myexperiment || { echo "Could not create myExperiment init.d script. Aborting ..."; exit 33; }
sudo mv ${tempdir}/myexperiment /etc/init.d || { echo "Could not move myExperiment init.d script to /etc/init.d. Aborting ..."; exit 34; }
sudo chown root:root /etc/init.d/myexperiment || { echo "Could not change ownwership of /etc/init.d/myexperiment. Aborting ..."; exit 35; }
sudo chmod +x /etc/init.d/myexperiment || { echo "Could not modify permissions of /etc/init.d/myexperiment. Aborting ..."; exit 36; }
sudo chkconfig myexperiment on || { echo "Could not deploy /etc/init.d/myexperiment as a startup script. Aborting ..."; exit 37; }

echo "Adding Firewall rules for mongrel webserver on IPv4 and IPv6"
sudo chkconfig iptables on || { echo "Failed to iptables to applications started at boottime. Aborting ..."; exit 38; }
sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited || { echo "Could not delete rule from iptables. Aborting ..."; exit 39; }
sudo iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport ${myexp_port_no} -j ACCEPT || { echo "Could not add rule from iptables. Aborting ..."; exit 40; }
sudo iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25 -j ACCEPT || { echo "Could not add rule from iptables. Aborting ..."; exit 41; }
sudo iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited  || { echo "Could not add rule from iptables. Aborting ..."; exit 42; }
sudo iptables-save | sudo tee /etc/sysconfig/iptables >/dev/null  || { echo "Could not save new iptables rules. Aborting ..."; exit 43; }
sudo restorecon -v /etc/sysconfig/iptables || { echo "Could not restorecon for /etc/sysconfig/iptables. Aborting ..."; exit 44; }
sudo service iptables restart || { echo "Could not restart iptables. Aborting ..."; exit 45; }

sudo chkconfig ip6tables on || { echo "Failed to ip6tables to applications started at boottime. Aborting ..."; exit 46; }
sudo ip6tables -D INPUT -j REJECT --reject-with icmp6-adm-prohibited || { echo "Could not delete rule from ip6tables. Aborting ..."; exit 47; }
sudo ip6tables -A INPUT -m state --state NEW -m tcp -p tcp --dport ${myexp_port_no} -j ACCEPT || { echo "Could not add rule from ip6tables. Aborting ..."; exit 48; }
sudo ip6tables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25 -j ACCEPT || { echo "Could not add rule from ip6tables. Aborting ..."; exit 49; }
sudo ip6tables -A INPUT -j REJECT --reject-with icmp6-adm-prohibited || { echo "Could not delete rule from ip6tables. Aborting ..."; exit 50; }
sudo ip6tables-save | sudo tee /etc/sysconfig/ip6tables >/dev/null || { echo "Could not save new ip6tables rules. Aborting ..."; exit 51; }
sudo restorecon -v /etc/sysconfig/ip6tables || { echo "Could not restorecon for /etc/sysconfig/ip6tables. Aborting ..."; exit 52; }
sudo service ip6tables restart || { echo "Could not restart ip6tables. Aborting ..."; exit 53; }

sudo service myexperiment start || { echo "Could not start myExperiment. Aborting ..."; exit 54; }

echo "Removing temporary directory created for writing patch files to"
sudo rm -rf ${tempdir} || { echo "Could not remove temporary directory used by patch files."; exit 55; }

echo ""
echo "========================================================================================================"
echo " myExperiment is now fully installed. Go to http://${myexp_cname}:${myexp_port_no}/ to use myExperiment"
echo " To start, stop or restart myExperiment use: sudo service myexperiment start|stop|restart" 
echo "========================================================================================================"

