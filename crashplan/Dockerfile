FROM ubuntu:trusty

RUN apt-get update && apt-get install -y wget openjdk-7-jre-headless && apt-get clean
ADD CrashPlan_3.7.0_Linux.tgz /tmp/
ADD install-unattended.sh /tmp/CrashPlan-install/install-unattended.sh
RUN ls
RUN /tmp/CrashPlan-install/install-unattended.sh
ADD run.sh /run.sh

EXPOSE 4243
VOLUME /mnt/crashplan 

CMD ["/run.sh"]