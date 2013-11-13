#!/usr/bin/env bash

# ruby, java, git, curl and couchdb
apt-get update
apt-get install ruby openjdk-7-jdk curl git couchdb -y

# config ruby gems to https and rvm
gem sources -r http://rubygems.org/
gem sources -r http://rubygems.org
gem sources -a https://rubygems.org
curl -L https://get.rvm.io | bash -s stable
echo "source /usr/local/rvm/scripts/rvm" >> ~/.bashrc
source /usr/local/rvm/scripts/rvm
rvm get stable
rvm install $(cat /vagrant/.ruby-version) --verify-downloads 1 --max-time 200 --binary
gem install bundler

# initial config of app
cd /vagrant
bundle install
cp config.yml.dist config.yml
#nohup rackup &

