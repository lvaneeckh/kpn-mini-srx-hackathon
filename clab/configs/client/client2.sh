
#!/bin/bash
# Copyright 2024 Nokia
# Licensed under the BSD 3-Clause License.
# SPDX-License-Identifier: BSD-3-Clause

ip link set lo up || true
ip link set eth1 down || true
ip link set eth2 down || true
ip link set eth1 mtu 9500
ip link set eth2 mtu 9500
ip link add bond0 type bond 2>/dev/null || true
echo 802.3ad        > /sys/class/net/bond0/bonding/mode
echo 100            > /sys/class/net/bond0/bonding/miimon
echo layer3+4       > /sys/class/net/bond0/bonding/xmit_hash_policy
echo fast           > /sys/class/net/bond0/bonding/lacp_rate
echo 1              > /sys/class/net/bond0/bonding/min_links
echo 200            > /sys/class/net/bond0/bonding/updelay
ip link set bond0 address 00:c1:00:dc:01:12
ip link set bond0 mtu 9500
ip link set eth1 master bond0
ip link set eth2 master bond0
ip link set bond0 up
sleep 5

## VLAN 1
ip link add link bond0 name bond0.1 type vlan id 1 2>/dev/null || true
ip addr add 10.64.30.12/24 dev bond0.1
ip addr add fd00:fde8:0:30::12/64 dev bond0.1
ip link set bond0.1 up

ip route replace 10.0.0.0/8 via 10.64.30.1 dev bond0.1
ip -6 route replace fd00:fde8::/32 via fd00:fde8:0:30::1 dev bond0.1

## VLAN 101
ip link add link bond0 name bond0.101 type vlan id 101 2>/dev/null || true
ip addr add 192.168.30.12/24 dev bond0.101
ip addr add fd00:ffdd:0:30::12/64 dev bond0.101
ip link set bond0.101 up

ip route replace 192.168.0.0/16 via 192.168.30.1 dev bond0.101
ip -6 route replace fd00:ffdd::/32 via fd00:ffdd:0:30::1 dev bond0.101

## VLAN 200
ip link add link bond0 name bond0.200 type vlan id 200 2>/dev/null || true
ip addr add 10.65.34.12/24 dev bond0.200
ip link set bond0.200 up

ip route replace 10.65.0.0/16 via 10.65.34.1 dev bond0.200

## VLAN 300
ip link add link bond0 name bond0.300 type vlan id 300 2>/dev/null || true
ip addr add 10.30.0.12/24 dev bond0.300
ip addr add fd00:fdfd:0:3000::12/64 dev bond0.300
ip link set bond0.300 up

## VLAN 312
ip link add link bond0 name bond0.312 type vlan id 312 2>/dev/null || true
ip addr add 10.30.2.12/24 dev bond0.312
ip addr add fd00:fdfd:0:3002::12/64 dev bond0.312
ip link set bond0.312 up

ip route replace 10.30.0.0/16 via 10.30.2.1 dev bond0.312
ip -6 route replace fd00:fdfd::/32 via fd00:fdfd:0:3002::1 dev bond0.312



## Keying infra
mkdir -p /home/admin/.ssh
touch /home/admin/.ssh/authorized_keys
chmod 600 /home/admin/.ssh/authorized_keys
cat /tmp/authorized_keys > /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh

echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "admin:$USER_PASSWORD" | chpasswd
