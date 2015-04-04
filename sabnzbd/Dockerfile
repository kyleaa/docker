# Based off of https://github.com/timhaak/docker-sabnzbd
# Switched base image and process monitoring - the timhaak image keeps running after sabnzb exists and does not restart

FROM phusion/baseimage
MAINTAINER Kyle Anderson <kyleaa@gmail.com>

# To get rid of error messages like "debconf: unable to initialize frontend: Dialog":
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN echo "deb http://archive.ubuntu.com/ubuntu trusty multiverse" >> /etc/apt/sources.list

RUN apt-get -q update

RUN apt-get install -qy python-software-properties software-properties-common

RUN add-apt-repository -y  ppa:jcfp/ppa

RUN apt-get -q update

RUN apt-get install -qy --force-yes sabnzbdplus
RUN apt-get install -qy --force-yes sabnzbdplus-theme-classic sabnzbdplus-theme-mobile sabnzbdplus-theme-plush
RUN apt-get install -qy --force-yes par2 python-yenc unzip unrar

# apt clean
RUN apt-get clean &&\
  rm -rf /var/lib/apt/lists/* &&\
  rm -rf /tmp/*

VOLUME /config
VOLUME /data

EXPOSE 8080 9090

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
run mkdir /etc/service/sabnzbd
add sabnzbd.runit /etc/service/sabnzbd/run
