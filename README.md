# My other PXE server is a container

This is a Dockerfile to build a container running a PXE server,
pre-configured to serve a Debian netinstall kernel and initrd.

## Quick start

1. Of course you need Docker first!
1. Clone this repo and `cd` into the repo checkout.
1. Build the container with `docker build -t pxe .`
1. Run the container with `PXECID=$(docker run -d pxe)`
1. Give it an extra network interface with `./pipework br0 $PXECID 192.168.242.1/24`
1. Put the network interface connected to your machines on the same bridge
   with e.g. `brctl addif br0 eth0` (don't forget to move `eth0` IP address
   to `br0` if there is one).
1. You can now boot PXE machines on the network connected to `eth0`!
   Alternatively, you can put VMs on `br0` and achieve the same result.


## I want to netboot something else!

Left as an exercise for the reader. Check the Dockerfile and rebuild;
it should be easy enough.


## Can I change the IP address, 192.168.242.1...?

Yes, if you also change it in the Dockerfile.


## Can I *not* use pipework?

Yes, but it will be more complicated. You will have to:

- make sure that Docker UDP can handle broadcast packets (since PXE/DHCP
  uses broadcast packets);
- make sure that UDP ports are correctly mapped;
- auto-detect the gateway address and DNS server, instead of using the
  container as a router+DNS server;
- maybe something else that I overlooked.


## I want MOAR fun!

Let's have a game!

1. Burn a [boot2docker](https://github.com/steeve/boot2docker) ISO on
   a blank CD.
1. With that CD, boot a physical machine.
1. Run the PXE container on Docker on the physical machine.
1. Pull the ubuntu container, start it in privileged mode, apt-get install
   QEMU in it, and start a QEMU VM, mapping its hard disks to the real
   hard disk of the machine, and bridging it with the PXE container.
1. The QEMU VM will netboot from the PXE container. Install Debian.
1. Reboot the physical machine -- it now boots on Debian. 
1. Repeat steps but install Windows for trolling purposes.
