To run:

    docker-compose up

or to rebuild:

    docker-compose up --build

To run commands/tasks:

    docker-compose exec app /bin/bash -l -c rake db:create
    docker-compose exec app /bin/bash -l -c rake db:migrate
    docker-compose exec app /bin/bash -l -c rake myexp:triplestore:create

To open the console:

    docker-compose exec app /bin/bash -l -c script/console
