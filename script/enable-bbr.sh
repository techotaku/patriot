#!/bin/sh

uname -r

sudo modprobe tcp_bbr

echo "tcp_bbr" | sudo tee -a /etc/modules-load.d/modules.conf

echo "net.core.default_qdisc = fq"  | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr
