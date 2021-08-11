#!/bin/sh

crond -b
bird -c /etc/bird/bird.conf
chmod 777 /var/run/bird.ctl
sed -i "s/8180/$PORT/g" /etc/lighttpd/lighttpd.conf
lighttpd -f /etc/lighttpd/lighttpd.conf -D
