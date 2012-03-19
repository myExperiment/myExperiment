myExperiment Fedora/RedHat/CentOS Installer Instructions
========================================================

The files in this directory are an installer for myExperiment on Fedora 13 and
consequently RedHat 6 and CentOS 6.0.  The installer is designed to work on a 
freshly installed version of these operating systems, you may have problems if 
you are installing on an existing system, which has configuration that 
conflicts with that in the installer.

install.bash is the main installer script and can be run from the current 
working directory as follows:

  /bin/bash install.bash

This install script requires the settings file, settings.bash, which needs to 
be kept in the same directory.  This can be created by copying the
default_settings.bash to settings.bash and making the following changes
before running install.bash:

myexp_root_password - 
  Choose a password for the root account of MySQL.  If for whatever reason 
  MySQL is already installed set this to the current MySQL root password.  
  MySQL must have a root password for the installer to succeed. See
  http://forums.mysql.com/read.php?10,355736 if you want to have set no MySQL
  password after the installer has run.

fq_server_name - 
  The fully-qualified server name, i.e. the A record. 
  E.g. myexperiment.example.org

sendmail_smarthost_server - 
  The mail server you want to user as a relay for emails.
  E.g. smtp

sendmail_smarthost_domain - 
  The domain of the mail server you want to user as a relay for emails.
  E.g. example.org

myexp_cname - 
  The location you intend to host the myExperiment site.  This may be the 
  same as fq_server_name.
  E.g. myexperiment.example.org


== Post-installation configuration ==

The installer is designed to work on a freshly installed version of Fedora 13 
/ RedHat 6 / CentOS 6.0 and will do minimal configuration of myExperiment.  
To do further configuration you will need to edit settings file in the config 
directory of the SVN checkout of myExperiment by default this is: 

  /var/rails/myexperiment/config/settings.yml

Some configuration may require restarting myExperiment using the following command:

  sudo service myexperiment restart


== Further Information ==

Please refer to the wiki page:

  http://wiki.myexperiment.org/index.php/Developer:FedoraInstallation
