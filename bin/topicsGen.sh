#!/bin/bash

# place the file mySQLConnectBundle.properties
# into the current directory

jar uf TopicsGenerator.jar mySQLConnectBundle.properties
java -jar TopicsGenerator.jar --num-topics 20 --optimize-interval 10 --num-top-words 20 >> topicsExplorer.log 2>&1
