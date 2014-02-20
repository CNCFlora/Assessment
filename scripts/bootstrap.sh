#!/usr/bin/env bash

# ruby, java, git, curl and couchdb
apt-get update
apt-get install default-jre-headless curl git couchdb libgd2-noxpm tmux vim libxslt-dev libxml2-dev ruby ruby1.9.1-dev -y

# startup setup
sed -i -e 's/exit/#exit/g' /etc/rc.local
echo 'echo $(date) > /var/log/rc.log ' > /etc/rc.local
echo 'su vagrant -c "cd /vagrant && nohup rackup &" >> /var/log/rc.log 2>&1' >> /etc/rc.local
echo 'SUBSYSTEM=="bdi",ACTION=="add",RUN+="/vagrant/scripts/register.sh >> /var/log/rc.log 2>&1"' > /etc/udev/rules.d/50-vagrant.rules

# config ruby gems to https
gem sources -r http://rubygems.org
gem sources -r http://rubygems.org/
gem sources -a https://rubygems.org
gem install bundler

# add rbenv
su vagrant -c 'git clone https://github.com/sstephenson/rbenv.git ~/.rbenv'
su vagrant -c "echo 'export PATH=\"$HOME/.rbenv/bin:$PATH\"' >> ~/.bash_profile"
su vagrant -c "echo 'eval \"$(rbenv init -)\"' >> ~/.bash_profile"
su vagrant -c 'git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build'

# initial config of app
cd /vagrant
bundle install
[[ ! -e config.yml ]] && cp config.yml.dist config.yml

# register the service
cd /vagrant && ./scripts/register.sh

