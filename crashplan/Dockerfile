FROM ubuntu:trusty

RUN apt-get update && apt-get install -y wget && apt-get clean
ADD CrashPlan_3.7.0_Linux.tgz /tmp/
ADD install-unattended.sh /tmp/CrashPlan-install/install-unattended.sh
RUN /tmp/CrashPlan-install/install-unattended.sh

EXPOSE 4243
VOLUME /mnt/crashplan 

CMD ["/usr/local/crashplan/bin/CrashPlanEngine","start"]
