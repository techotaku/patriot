#!/bin/sh

uname -r
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9.43/linux-headers-4.9.43-040943_4.9.43-040943.201708122332_all.deb
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9.43/linux-headers-4.9.43-040943-generic_4.9.43-040943.201708122332_amd64.deb
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9.43/linux-image-4.9.43-040943-generic_4.9.43-040943.201708122332_amd64.deb
sudo dpkg -i linux-*.deb
rm linux-*.deb
