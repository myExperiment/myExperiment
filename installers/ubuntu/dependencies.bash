#!/bin/bash

echo "Installing required packages using apt-get install"
sudo apt-get update || { echo "Could not update apt-get. Aborting ..."; exit 5; }
sudo -n apt-get install -y build-essential exim4 git-core curl libcurl3 libcurl3-gnutls libcurl4-gnutls-dev openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev mysql-server libmysqlclient-dev libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion libmagickwand-dev graphviz gcj-jre-headless || { echo "Could not install required using apt-get install. Aborting ..."; exit 6; }

