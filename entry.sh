#!/bin/sh

if [[ -z "${IP4}" ]]; then
	echo "IPv4 Not Set."
else
	ip addr add $IP4 dev eth1
fi

if [[ -z "${IP6}" ]]; then
	echo "IPv6 Not Set."
else
	ip addr add $IP6 dev eth1
fi

crond -b
bird -c /etc/bird/bird.conf
/update_config.sh
chmod 777 /var/run/bird.ctl
sed -i "s/8180/$PORT/g" /etc/lighttpd/lighttpd.conf
lighttpd -f /etc/lighttpd/lighttpd.conf -D
