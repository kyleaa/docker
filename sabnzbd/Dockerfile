# Based off of https://github.com/timhaak/docker-sabnzbd
# Switched base image and process monitoring - the timhaak image keeps running after sabnzb exists and does not restart

FROM phusion/baseimage:jammy-1.0.2
MAINTAINER Kyle Anderson <kyleaa@gmail.com>

# To get rid of error messages like "debconf: unable to initialize frontend: Dialog":
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN echo "deb http://archive.ubuntu.com/ubuntu jammy multiverse" >> /etc/apt/sources.list

RUN add-apt-repository -y ppa:jcfp/nobetas && \
    add-apt-repository -y ppa:jcfp/sab-addons && \
    apt-get -q update && apt-get dist-upgrade -y && \
    apt-get install -qy \
      sabnzbdplus par2-turbo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

VOLUME /config
VOLUME /data

EXPOSE 8080 9090

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
run mkdir /etc/service/sabnzbdplus
add sabnzbd.runit /etc/service/sabnzbdplus/run
