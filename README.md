# Assessment

CNCFlora app to handle the risk assessments.

## Deployment

Use docker:
  
  docker run -d -p 8282:8080 -t cncflora/assessment

You will need to have access to etcd, connect, couchdb and elasticsearch.

## Development

Start with git:

  git clone git@github.com:CNCFlora/assessment
  cd assessment

Use [vagrant](http://vagrantup.com) and [virtualbox](http://virtualbox.org):

  vagrant up
  vagrant ssh
  cd /vagrant


To start the test server, available at http://192.168.50.13:9292:

  rackup -o 0.0.0.0

Run tests:

  rspec tests/\*.rb

Build the container for deployment:

  docker build -t cncflora/assessments .
  docker push cncflora/assessments 

## License

Apache License 2.0

