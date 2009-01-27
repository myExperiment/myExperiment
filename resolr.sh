#!/bin/bash

export RAILS_ENV=production

echo 'Workflow.rebuild_solr_index' | ruby script/console
echo 'Blob.rebuild_solr_index'     | ruby script/console
echo 'User.rebuild_solr_index'     | ruby script/console
echo 'Network.rebuild_solr_index'  | ruby script/console
echo 'Pack.rebuild_solr_index'     | ruby script/console

