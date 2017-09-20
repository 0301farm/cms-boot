function mount_chroot () {
	sudo mount -o bind /dev target/dev
	sudo mount -t devpts none target/dev/pts
	sudo mount -t proc none target/proc
	sudo mkdir -p target/build
	sudo mount -o bind sources target/build
}

function umount_chroot () {
	sudo umount -l target/dev/pts
	sudo umount -l target/dev
	sudo umount -l target/proc
	sudo umount -l target/build
}
