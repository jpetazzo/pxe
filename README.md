# My other PXE server is a container

This is a Dockerfile to build a container running a PXE server,
pre-configured to serve a Debian netinstall kernel and initrd.

## Quick start

1. Of course you need Docker first!
1. Clone this repo and `cd` into the repo checkout.
1. Build the container with `docker build -t pxe .`
1. Run the container with `PXECID=$(docker run --cap-add NET_ADMIN -d pxe)`
1. Give it an extra network interface with `./pipework br0 $PXECID 192.168.242.1/24`
1. Put the network interface connected to your machines on the same bridge
   with e.g. `brctl addif br0 eth0` (don't forget to move `eth0` IP address
   to `br0` if there is one).
1. You can now boot PXE machines on the network connected to `eth0`!
   Alternatively, you can put VMs on `br0` and achieve the same result.


### Why and how do we move eth0 IP address to br0?

The Linux network stack has the notion of master and slave interfaces.
They are used in many places, including bridges and bonding (when
multiple physical interfaces are grouped together to form a single
logical link, for increased throughput or reliability). When using
Linux bridges, the bridge is the master interface, and all the ports
of the bridge are slave interfaces.

Now is the tricky part: with interfaces like bridges and bonding
groups, only the master should have IP addresses; not the slaves.
If an IP address is configured on a slave interface, it will misbehave
in seemingly random ways. For instance, it can stop working if
the interface is down (but the master interface is still up).
Or it might handle some protocols like ARP only for packets
inbound on this interface.

Therefore, when changing the configuration of an existing interface
to place it inside a bridge (or bonding group), you should
deconfigure its IP address, and assign it to the master interface
instead. I recommend the following steps:

1. Check the IP address of the interface (with e.g. `ip addr ls eth0`).
   Carefully note the IP address *and its subnet mask*, e.g.
   192.168.1.4/24. There can be multiple addresses; in that case,
   note all of them.
2. Check if there are special routes going through that interface.
   Chances are, that there is a default route, and you will have to
   take care of it; otherwise you will lose internet connectivity.
   The easiest way is to do `ip route ls dev eth0`. You will almost
   certainly see an entry with `proto kernel scope link`, which
   is the automatic entry corresponding to the subnet directly
   connected to this interface. You can ignore this one. However,
   if you see something like `default via 192.168.1.1`, note it.
3. Deconfigure the IP address. In that case, we would do
   `ip addr del 192.168.1.4/24 dev eth0`. You don't havea to
   deconfigure the routes: they will be automatically removed
   as the address is withdrawn.
4. Configure the IP address on the bridge. In our example, that would
   be `ip addr add 192.168.1.4/24 dev br0`.
5. Last but not least, re-add the routes on the bridge. Here, we
   would do `ip route add default via 192.168.1.1`.

If you want to do that automatically at boot, you can do it through
the `/etc/network/interfaces` file (on Debian/Ubuntu). 

It will look like this (assuming the same IP addresses than our
previous example):

```
auto br0
iface br0 inet static
      address 192.168.1.4
      netmask 255.255.255.0
      network 192.168.1.0
      broadcast 192.168.1.255
      gateway 192.168.1.1
      bridge_ports eth0
      bridge_stp off
      bridge_fd 0
```

Don't forget to disable the section related to `eth0` then!


## I want to netboot something else!

Left as an exercise for the reader. Check the Dockerfile and rebuild;
it should be easy enough.

If you want to boot coreOS, check out [avlis/pxe_coreos](https://github.com/avlis/pxe_coreos)

## Can I change the IP address, 192.168.242.1...?

Yes. Be aware that the DHCP server on this container will offer IPs from 101 to 199 on the same /24 subnet. 
So make sure that the IP you give to the container via pipework does not clash with that.
Also make sure that there are no other hosts on that bridge within that range. 
Otherwise, change it in the Dockerfile, check the line that says --dhcp-range=(...).


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
