First create your .env file:

    cp sample.env .env

To run:

    docker-compose up

or to rebuild:

    GIT_COMMIT=`git rev-parse HEAD`; docker-compose up --build

To run commands/tasks:

    docker-compose exec app /bin/bash -l -c "bundle exec rake db:create"
    docker-compose exec app /bin/bash -l -c "bundle exec rake db:migrate"
    docker-compose exec app /bin/bash -l -c "bundle exec rake myexp:triplestore:create"

To open the console:

    docker-compose exec app /bin/bash -l -c "bundle exec script/console"

Refresh solr index:

    docker-compose exec app /bin/bash -l -c "bundle exec rake myexp:refresh:solr"

To import a database dump:

*Is done using plain docker due to docker-compose not being good at piping*

    docker exec -i myexperiment-mysql mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE < path-to-some-dump-file.sql

Replace `$MYSQL_USER`, `$MYSQL_PASSWORD` and `$MYSQL_DATABASE` with appropriate credentials/env vars (e.g. `source .env`)

To export a database dump:

    docker exec -i myexperiment-mysql mysqldump --max_allowed_packet=1073741824 --user=root --password=$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE > path-to-some-dump-file.sql

Replace `$MYSQL_ROOT_PASSWORD` and `$MYSQL_DATABASE`.
