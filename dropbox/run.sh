#!/bin/bash
adduser --gecos "Dropbox" --disabled-password --gid=0 --uid=$DROPBOX_UID --home=/home/dropbox --shell=/bin/bash dropbox
chown -R dropbox:root /home/dropbox
su -l dropbox /home/dropbox/.dropbox-dist/dropboxd
