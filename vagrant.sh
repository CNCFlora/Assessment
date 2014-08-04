#!/usr/bin/env bash

# basic stuff
if [[ ! -e /root/.apt_done ]]; then
    add-apt-repository ppa:brightbox/ruby-ng -y
    apt-get update
    apt-get upgrade -y
    apt-get install wget curl git ruby2.1 ruby2.1-dev -y
    touch /root/.apt_done
fi

# setup app deps
if [[ ! -e /root/.app_done ]]; then
    # config ruby gems to use https
    gem sources -r http://rubygems.org/
    gem sources -a https://rubygems.org/

    # uh?
    gem install bundler
    #cd /vagrant && bundle install

    # initial config of app
    #su vagrant -lc 'cd /vagrant && gem install bundler'
    su vagrant -lc 'cd /vagrant && bundle install'
    touch /root/.app_done
fi

# docker register to etcd
if [[ ! -e /root/.ops_done ]]; then
    gem install small-ops
    touch /root/.ops_done
fi

docker2etcd -h 192.168.50.13 -e http://192.168.50.13:4001

# setup couchdb
if [[ ! -e /root/.db_done ]]; then
    HUB=$(docker ps | grep datahub | awk '{ print $10 }' | grep -e '[0-9]\{5\}' -o)
    curl -X PUT http://localhost:$HUB/cncflora
    curl -X PUT http://localhost:$HUB/cncflora_test
    touch /root/.db_done
fi

