#!/usr/bin/env bash

# install the connect app
cd ~
[[ ! -e lein ]] && wget https://raw.github.com/technomancy/leiningen/stable/bin/lein -O lein
chmod +x lein
chown vagrant lein
[[ ! -e Connect ]] && git clone https://github.com/CNCFlora/Connect.git
chown vagrant Connect -Rf
[[ ! -e /var/lib/floraconnect ]] && mkdir -p /var/lib/floraconnect
chown vagrant /var/lib/floraconnect -Rf
cd Connect
~/lein deps
nohup ~/lein ring server-headless &
echo 'cd /root/Connect && nohup /root/lein ring server-headless &' >> /etc/rc.local
echo "Waiting server..."
sleep 10


