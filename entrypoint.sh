#!/bin/sh
## entrypoint.sh
## Container's init script.
##
## Author: Nathan Campos <nathan@innoveworkshop.com>

/usr/sbin/sshd -D &
apache2ctl -D FOREGROUND
