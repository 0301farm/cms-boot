NPROC:=$(shell nproc)

CFLAGS:=-O -static

BUILDROOT_VERSION:=2017.02.2
CC:=build/buildroot-${BUILDROOT_VERSION}/output/host/usr/bin/x86_64-buildroot-linux-musl-gcc

# Kernel config to use.
# You can either use an existing config, or set the variable "KCUSTOMCONFIG"
# to y to use the default config and then call a make menuconfig in the kernel
# source directory.
KCONFIG=default
KCUSTOMCONFIG=

# Kernel version.
KVERS=4.9.51

# xz compression level.
LVL=6

all: sources/linux-${KVERS}/arch/x86_64/boot/bzImage sources/init sources/kexec
	mkdir -p output
	cp sources/linux-${KVERS}/arch/x86/boot/bzImage output/kernel.img
	mkdir -p initrd
	cp sources/init initrd/
	mkdir initrd/bin -p
	cp sources/kexec initrd/bin/
	cp stardust/target/x86_64-unknown-linux-musl/release/stardust initrd/bin/
	cp "build/buildroot-${BUILDROOT_VERSION}/output/target/bin/busybox" initrd/bin/
	cp "build/buildroot-${BUILDROOT_VERSION}/output/target/usr/sbin/mke2fs" initrd/bin/mkfs.ext4
	cd initrd && find ./ | cpio -H newc -o | xz -C crc32 --x86 -${LVL} > ../output/initrd.img

build/buildroot-${BUILDROOT_VERSION}.tar.bz2:
	cd build && wget -c "https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.bz2"

build/buildroot-${BUILDROOT_VERSION}: build/buildroot-${BUILDROOT_VERSION}.tar.bz2
	cd build && tar xvf buildroot-${BUILDROOT_VERSION}.tar.bz2

build/buildroot-${BUILDROOT_VERSION}/output: build/buildroot-${BUILDROOT_VERSION} config/buildroot-${BUILDROOT_VERSION}.config
	cp config/buildroot-${BUILDROOT_VERSION}.config build/buildroot-${BUILDROOT_VERSION}/.config
	cd build/buildroot-${BUILDROOT_VERSION} && yes "" | ${MAKE} oldconfig
	cd build/buildroot-${BUILDROOT_VERSION} && ${MAKE} -j ${NPROC}
	touch build/buildroot-${BUILDROOT_VERSION}/output

config/linux-${KCONFIG}: 
	test -f config/linux-${KCONFIG} || test "y" = "${KCUSTOMCONFIG}" && cp config/linux-default config/linux-${KCONFIG}

sources/linux-${KVERS}.tar.xz: 
	wget https://kernel.org/pub/linux/kernel/v4.x/linux-${KVERS}.tar.xz -O sources/linux-${KVERS}.tar.xz

sources/linux-${KVERS}: sources/linux-${KVERS}.tar.xz 
	tar xf sources/linux-${KVERS}.tar.xz -C sources/

sources/linux-${KVERS}/arch/x86_64/boot/bzImage: sources/linux-${KVERS} config/linux-${KCONFIG} Makefile 
	cp config/linux-${KCONFIG} sources/linux-${KVERS}/.config
	cd sources/linux-${KVERS} && ${MAKE} -j ${NPROC} && cd ../../

sources/kexec: build/buildroot-${BUILDROOT_VERSION}/output
	${CC} ${CFLAGS} sources/kexec.c -o sources/kexec
	strip --strip-debug --strip-unneeded sources/kexec

stardust/target/x86_64-unknown-linux-musl/release/stardust: stardust 
	cd stardust && cargo build --release --target=x86_64-unknown-linux-musl
	strip --strip-all stardust/target/x86_64-unknown-linux-musl/release/stardust

clean:
	rm -rf output build/*
