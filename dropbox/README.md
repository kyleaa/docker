kyleaa/dropbox
==============

Run using the following syntax:
docker run -d --name='dropbox-client' -e DOCKER_UID=1027 --net='host' -v /mnt/user/.dropbox:/home/dropbox/.dropbox -v /mnt/user/Dropbox:/home/dropbox/Dropbox/ kyleaa/dropbox
