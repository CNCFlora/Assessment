# CNCFlora Assessment Tool 

## Deployment

TODO

## Development

Start with git, obviously:

    # aptitude install git

Now clone the app, and enter it's directory:

    $ git clone git@github.com:CNCFlora/Assessment.git 
    $ cd Assessment

### Vagrant

Default is to use vagrant to simplify development, install [VirtualBox](http://virtualbox.org) and [Vagrant](http://vagrantup.org) and start the VM:

    $ vagrant up

And, to run the server:

    $ vagrant ssh -c "cd /vagrant && rackup"

To run tests:

    $ vagrant ssh -c "cd /vagrant && rspec tests/"

The app will be running on 9494, connect(auth) at 3001 and couchdb on 5999. 

Remember to create an user on the connect app (at http://localhost:3001).

