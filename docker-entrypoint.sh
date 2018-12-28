#!/usr/bin/env bash

export PATH=/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
[[ -f /etc/afp.conf ]] || printf '[Global]\n[Test]\npath = /tmp\n' > /etc/afp.conf

exec netatalk -d
