#!/usr/bin/env bash

# basic stuff
if [[ ! -e /root/.apt_done ]]; then
    add-apt-repository ppa:brightbox/ruby-ng -y
    apt-get update
    apt-get upgrade -y
    apt-get install wget curl git ruby2.1 ruby2.1-dev zlib1g-dev build-essential -y
    touch /root/.apt_done
fi

# setup app deps
if [[ ! -e /root/.app_done ]]; then
    # config ruby gems to use https
    gem sources -r http://rubygems.org/
    gem sources -a https://rubygems.org/

    # uh?
    gem install bundler

    # initial config of app
    su vagrant -lc 'cd /vagrant && gem install bundler'
    su vagrant -lc 'cd /vagrant && bundle install'
    touch /root/.app_done
fi

# setup couchdb
if [[ ! -e /root/.db_done ]]; then
    HUB=5984
    curl -X PUT http://localhost:$HUB/cncflora
    curl -X PUT http://localhost:$HUB/cncflora_test
    touch /root/.db_done
fi

