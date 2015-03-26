#!/bin/bash
id -u dropbox &>/dev/null || adduser --gecos "Dropbox" --disabled-password --gid=0 --uid=$DROPBOX_UID --home=/home/dropbox --shell=/bin/bash dropbox
chown -R dropbox:root /home/dropbox
chmod -R u+rw /home/dropbox/Dropbox /home/dropbox/.dropbox /home/dropbox/.dropbox-master
su -l dropbox /home/dropbox/.dropbox-dist/dropboxd
