kyleaa/dropbox
==============

Run using the following syntax:
docker run -d --name='dropbox-client' --hostname=docker-client -e DROPBOX_UID=1027 -v /mnt/user/.dropbox:/home/dropbox/.dropbox -v /mnt/user/Dropbox:/home/dropbox/Dropbox/ kyleaa/dropbox

Note: host-only networking causes su to crash the container
Dropbox names all clients with hostname, so go ahead and set that.
