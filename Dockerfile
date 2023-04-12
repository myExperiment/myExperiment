FROM ubuntu:16.04

# Dependencies
RUN apt-get update && apt-get install -y build-essential exim4 curl libcurl3 libcurl3-gnutls \
    libcurl4-gnutls-dev openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev \
    libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison \
    libmagickwand-dev graphviz gcj-jre-headless graphicsmagick-libmagick-dev-compat libgmp-dev \
    libgdbm-dev libffi-dev libgmp-dev openjdk-8-jdk gnupg2 mysql-client libmysqlclient-dev

# RVM
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    \curl -sSL https://get.rvm.io | bash

# Ruby
RUN /bin/bash -l -c "rvm install ruby-1.9.2-p320 --rubygems 1.8.25"

# Set work dir
WORKDIR /code

# App user
RUN useradd --create-home --shell /bin/bash myexperiment && usermod -aG rvm myexperiment && \
    chown myexperiment:myexperiment /code

USER myexperiment

# Gems
COPY Gemfile Gemfile.lock ./
RUN /bin/bash -l -c "gem install bundler --version 1.15.4"
RUN /bin/bash -l -c "rvm use ruby-1.9.2-p320"
RUN /bin/bash -l -c "NOKOGIRI_USE_SYSTEM_LIBRARIES=1 bundle install --deployment"

# Code
COPY . .

USER root
RUN chown -R myexperiment:myexperiment /code

# Expose port
EXPOSE 3000

CMD ["bash", "-l", "-c", "docker/entrypoint.sh"]
