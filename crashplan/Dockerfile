FROM ubuntu:trusty

RUN apt-get update && apt-get install -y wget && apt-get clean
ADD CrashPlan_3.7.0_Linux.tgz /tmp/
ADD install-unattended.sh /tmp/CrashPlan-install/install-unattended.sh
RUN ls /tmp/CrashPlan-install
RUN cd /tmp/CrashPlan-install/ && ./install-unattended.sh
RUN apt-get install -y supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 4243
VOLUME /mnt/crashplan 

CMD ["/usr/bin/supervisord"]