FROM ubuntu:trusty

RUN apt-get update && apt-get install -y python wget && apt-get clean -y
RUN cd /root/ && wget -O - "http://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
RUN wget -O /root/dropbox.py "http://www.dropbox.com/download?dl=packages/dropbox.py" && chmod 755 /root/dropbox.py

ADD run.sh /run.sh
RUN chmod 755 /run.sh

VOLUME /root/.dropbox /root/Dropbox
CMD ["/run.sh"]