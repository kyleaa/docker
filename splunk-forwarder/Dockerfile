FROM phusion/baseimage

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

run curl --insecure -o splunkforwarder.deb https://download.splunk.com/products/splunk/releases/6.2.2/universalforwarder/linux/splunkforwarder-6.2.2-255606-linux-2.6-amd64.deb && dpkg -i splunkforwarder.deb && rm splunkforwarder.deb
run mkdir /etc/service/splunkforwarder
add splunkforwarder.runit /etc/service/splunkforwarder/run


# cleanup
run rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
