#!/bin/sh

uname -r
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9.45/linux-headers-4.9.45-040945_4.9.45-040945.201708242131_all.deb
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9.45/linux-headers-4.9.45-040945-generic_4.9.45-040945.201708242131_amd64.deb
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9.45/linux-image-4.9.45-040945-generic_4.9.45-040945.201708242131_amd64.deb
sudo dpkg -i linux-*.deb
rm linux-*.deb
