#!/bin/bash
# Copyright 2024 Nokia
# Licensed under the BSD 3-Clause License.
# SPDX-License-Identifier: BSD-3-Clause

ip link set lo up || true
ip link set eth1 mtu 9500
ip link set eth1 up

## VLAN 1
ip link add link eth1 name eth1.1 type vlan id 1 2>/dev/null || true
ip addr add 10.64.30.14/24 dev eth1.1
ip addr add fd00:fde8:0:30::14/64 dev eth1.1
ip link set eth1.1 up

ip route replace 10.0.0.0/8 via 10.64.30.1 dev bond0.1
ip -6 route replace fd00:fde8::/32 via fd00:fde8:0:30::1 dev bond0.1

## VLAN 400
ip link add link eth1 name eth1.400 type vlan id 400 2>dev/null ||true
ip addr add 10.40.4.1/31
ip link set eth1.400 up


## Keying infra
mkdir -p /home/admin/.ssh
touch /home/admin/.ssh/authorized_keys
chmod 600 /home/admin/.ssh/authorized_keys
cat /tmp/authorized_keys > /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh

echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "admin:$USER_PASSWORD" | chpasswd
