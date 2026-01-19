#!/bin/bash

set -eu

##### SET THESE VARIABLES #####

usbstick="/usbstick.bin"
mountpoint="/mnt/usbstick"
size=16G

###############################

main() {
	validate
	overlay
	make_usbstick
	load_module
}

overlay() {
	# Set up dwc2 USB controller overlay (used to enable USB OTG/USB device)
	grep -q dwc2 /boot/firmware/config.txt || {
		echo "dtoverlay=dwc2" | tee -a /boot/firmware/config.txt
	}
	echo "dwc2" | tee /etc/modules-load.d/mass-storage
	ok "USB controller overlay done"
}

make_usbstick() {
	# Make a filesystem on a file
	[ -e "${usbstick}" ] || {
		truncate -s 16G "${usbstick}"
		mkdosfs "${usbstick}" -F 32 --mbr=yes -n PIMASSS
	}
	# Create the mountpoint
	[ -d "${mountpoint}" ] && {
		mkdir -pv "${mountpoint}"
		chmod -v +w "${mountpoint}"
	}
	# Add mount to fstab
	grep -q "${usbstick}" /etc/fstab || {
		echo "${usbstick} ${mountpoint} vfat rw,users,user,exec,umask=000 0 0" | tee -a /etc/fstab
	}
	# Mount filesystem
	mountpoint -q "${mountpoint}" || {
		mount "${mountpoint}"
	}
	ok "USB stick (size=${size}) created and mounted"
}

load_module() {
	lsmod | grep -q g_mass_storage || {
		modprobe g_mass_storage file="${usbstick}" stall=0 ro=0
	}
	ok "module loaded"
}

validate() {
	# The user of this script needs to have root privs
	[ "${EUID}" -eq 0 ] || {
		echo "You need to run this as root (or sudo)!"
		exit 1
	}
	# Check running on a RPi
	grep -qiE 'raspberry|bcm' /proc/cpuinfo || {
		echo "This is not a Raspberry Pi!"
		exit 3
	}
}

ok() {
	echo -e "\e[1;32m${1}\e[m"
}

main ${@}
