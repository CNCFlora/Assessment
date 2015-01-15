# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.network "private_network", ip: "192.168.50.13"

  config.vm.provision "docker" do |d|
    d.run "cncflora/etcd", name: "etcd", args: "-p 4001:4001"
    d.run "cncflora/connect", name: "connect", args: "-P -v /var/connect:/var/floraconnect:rw"
    d.run "cncflora/elasticsearch", name: "elasticsearch",args: "-p 9200"
    d.run "cncflora/couchdb", name: "couchdb", args: "-P --link elasticsearch:elasticsearch -v /var/couchdb:/var/lib/couchdb:rw"
    d.run "cncflora/dwc-services", name: "dwc-services", args: "-P"
    d.run "cncflora/floradata", name: "floradata", args: "-P"
    d.run "cncflora/checklist", name: "checklist", args: "-P"
  end

  config.vm.provision :shell, :path => "vagrant.sh"
end

