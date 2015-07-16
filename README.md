# Assessment

CNCFlora app to handle the risk assessments.

## Deployment

This app is intend to run as part of the [CNCFlora Nuvem](http://github.com/cncflora/nuvem) apps.

To run standalone, you will need [docker](http://docker.com) and [docker-compose](http://docs.docker.com/compose):

Clone the project, access it and run the containers:

    $ git clone git@github.com:CNCFlora/assessment.git
    $ cd assessment
    $ make start

## Development

You will need [docker](http://docker.com) and [docker-compose](http://docs.docker.com/compose).

The whole project is supposed to run inside a docker container, isolated, including the tests, build and etc.

Start with git:

    $ git clone git@github.com:CNCFlora/assessment
    $ cd assessment

The tasks are defined in the Makefile.

To run the app in dev mode:

    $ make start # run in background
    $ make logs # follow logs
    $ make stop # stop all runing

This will take a while the first time, as it download the needed services (like couchdb, elasticsearch and etc).

Other relevant tasks:

    $ make test # run unit tests
    $ make build # builds docker container
    $ make push # pushes the container

## License

Apache License 2.0

