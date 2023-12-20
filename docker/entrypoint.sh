#!/bin/bash

cp docker/database.yml config/database.yml

mkdir -p log
touch log/production.log
tail -f log/production.log &

/bin/bash -l -c "rvm use ruby-1.9.2-p320 && bundle exec script/server"
