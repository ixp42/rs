#!/bin/sh

crond -b
bird -f -c /etc/bird/bird.conf
