# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "raring32"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-i386-vagrant-disk1.box"

  config.vm.provision :shell, :path => "scripts/bootstrap.sh"
  config.vm.provision :shell, :path => "scripts/datahub.sh" #couchdb, erica and design docs
  config.vm.provision :shell, :path => "scripts/connect.sh" #lein and connect app

  config.vm.network :forwarded_port, host: 9494, guest: 9292 # rackup
  config.vm.network :forwarded_port, host: 5999, guest: 5984 # couchdb
  config.vm.network :forwarded_port, host: 3001, guest: 3000 # connect
end

