#!/bin/bash

cp docker/database.yml config/database.yml
cp docker/sunspot.yml config/sunspot.yml

/bin/bash -l -c "rvm use ruby-1.9.2-p320 && bundle exec script/server"
