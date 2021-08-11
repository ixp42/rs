#!/bin/sh

crond -b
bird -c /etc/bird/bird.conf
chmod 777 /var/run/bird.ctl
lighttpd -f /etc/lighttpd/lighttpd.conf -D
