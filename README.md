# CNCFlora Assessment Tool 


## Deployment

TODO

## Development

Start with git, obviously:

    # aptitude install git

Now clone the app, and enter it's directory:

    $ git clone git@github.com:CNCFlora/Assessment.git 
    $ cd Assessment

You will need ruby, as expected:

    # aptitude install ruby

Install RVM for ruby versions control, them install jRuby:

    $ curl -L https://get.rvm.io | bash -s stable
    $ echo 'source $HOME/.rvm/scripts/rvm' >> ~/.bashrc
    $ rvm install jruby
    $ rvm use jruby

Them bundler, to deal with dependencies:

    # gem install bundler

Use bundler to solve dependencies (take a look at Gemfile):

    $ bundle install

Install CouchDB and create our little database:

    # aptitude install couchdb
    # curl -X PUT http://localhost:5984/lilruby

Run the tests:

    $ rspec app_test.rb

Run the application:
    
    $ rackup

Create deployable war:

    $ warble war

