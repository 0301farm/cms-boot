#!/bin/bash

sudo mount -o bind /dev serverRoot/dev
sudo mount -t devpts none serverRoot/dev/pts
sudo mount -t proc none serverRoot/proc

HOME=/root sudo chroot serverRoot

sudo umount serverRoot/dev/pts
sudo umount serverRoot/dev
sudo umount serverRoot/proc
