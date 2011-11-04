myExperiment Ubuntu Installer Instructions
==========================================

The files in this directory are an installer for myExperiment on Ubuntu 10.04 
that has had all the latest updates installed (based on updates available on 
18/10/2011).  The installer is designed to work on a freshly installed version
of Ubuntu, you may have problems if you are installing on an existing system.

install.bash is the main install script and can be downloaded and run from 
the current working directory as follows:

  /bin/bash install.bash

This install script requires the settings file, settings.bash, which needs to be 
kept in th same directory.  This can be created by copying the
default_settings.bash to settings.bash and making the followiing changes
before running install.bash:

myexp_root_password - Choose a password for the root account of MySQL.  If for
whatever reason MySQL is already installed set this to the current MySQL root
password.  MySQL mosty have a root password for the installer to suceed

myexp_user_password - Choose a password for the account that myExperiment uses
to access databases it creates for storing myExperiment data.

fq_server_name - The fully-qualified server name for a machine, e.g
myexperiment.example.org

exim_smarthost - The mail server you want to user as a relay for emails
e.g. smtp.example.org


== Post-installation configuration ==

The installer is designed to work on a freshly installed version of Ubuntu and
will do minimal configuration of myExperiment.  To do further configuration
you will need to edit settings.yml in the config directory of the SVN checkout
of myExperiment by default this /var/rails/myexperiment/config/.

After updating the settings file you will need to restart the myExperiment 
server.  To do this go to the file
/var/rails/myexperiment/tmp/pids/mongrel.pid 
and copy the process id number in this file then run:

kill process_id
rm /var/rails/myexperiment/tmp/pids/mongrel.pid
ruby var/rails/myexperiment/script/server -d

