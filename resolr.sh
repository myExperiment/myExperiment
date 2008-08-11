#!/bin/bash

export RAILS_ENV=production

echo 'Workflow.find_all.map do |w| w.solr_save end' | ruby script/console
echo 'Blob.find_all.map do |b| b.solr_save end'     | ruby script/console
echo 'User.find_all.map do |u| u.solr_save end'     | ruby script/console
echo 'Network.find_all.map do |n| n.solr_save end'  | ruby script/console
echo 'Pack.find_all.map do |p| p.solr_save end'  	| ruby script/console

