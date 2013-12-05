#!/usr/bin/env bash

# ruby, java, git, curl and couchdb
apt-get update
apt-get install ruby openjdk-7-jdk curl git couchdb libgd2-noxpm tmux vim -y

cp /etc/rc.local /etc/rc.local.bkp
sudo sed -e 's/exit/#exit/g' /etc/rc.local.bkp > /etc/rc.local

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
[[ ! -e config.yml ]] && cp config.yml.dist config.yml
echo "Done bootstrap"

