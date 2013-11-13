#!/usr/bin/env bash

# configure couchdb to listen on 0.0.0.0
service couchdb stop
cp /etc/couchdb/local.ini /etc/couchdb/local.ini.bkp
sudo sed -e 's/;bind_address = [0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+/bind_address = 0.0.0.0/' /etc/couchdb/local.ini.bkp > /etc/couchdb/local.ini 
echo "service couchdb start" >> /etc/rc.local
service couchdb start

# install the datahub design docs
cd ~
git clone https://github.com/CNCFlora/Datahub.git
cd Datahub
curl -X PUT "http://localhost:5984/cncflora"
curl -X PUT "http://localhost:5984/cncflora_test"
cp config.ini-dist config.ini
. config.ini
for f in $(ls -d */); do
    echo $f $DEV
    ./erica push $f $DEV
    ./erica push $f $TEST
done;
cd ..

