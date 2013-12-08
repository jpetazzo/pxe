FROM stackbrew/debian:jessie
RUN apt-get -q update
RUN apt-get -qy install dnsmasq wget iptables syslinux-common xorriso
RUN wget --no-check-certificate https://raw.github.com/jpetazzo/pipework/master/pipework
RUN chmod +x pipework
RUN mkdir /tftp
WORKDIR /tftp
RUN cp /usr/lib/syslinux/pxelinux.0 .
RUN wget --no-check-certificate https://github.com/steeve/boot2docker/releases/download/v0.2/boot2docker.iso
RUN osirrox -indev boot2docker.iso -extract /boot /tftp
RUN mkdir pxelinux.cfg
RUN printf "DEFAULT linux\nLABEL linux\nKERNEL vmlinuz64\nAPPEND initrd=initrd.gz user=docker\n" >pxelinux.cfg/default
CMD \
    echo Setting up iptables... &&\
    iptables -t nat -A POSTROUTING -j MASQUERADE &&\
    echo Waiting for pipework to give us the eth1 interface... &&\
    /pipework --wait &&\
    echo Starting DHCP+TFTP server...&&\
    dnsmasq --interface=eth1 \
    	    --dhcp-range=192.168.242.2,192.168.242.99,255.255.255.0,1h \
	    --dhcp-boot=pxelinux.0,pxeserver,192.168.242.1 \
	    --pxe-service=x86PC,"Install Linux",pxelinux \
	    --enable-tftp --tftp-root=/tftp/ --no-daemon
# Let's be honest: I don't know if the --pxe-service option is necessary.
# The iPXE loader in QEMU boots without it.  But I know how some PXE ROMs
# can be picky, so I decided to leave it, since it shouldn't hurt.
