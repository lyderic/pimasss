#!/bin/bash

set -eu

##### SET THESE VARIABLES #####

usbstick="/usbstick.bin"
mountpoint="/data"
size=16G

###############################

main() {
	validate
	overlay
	make_usbstick
}

overlay() {
	# Set up dwc2 USB controller overlay (used to enable USB OTG/USB device)
	grep -qE '^dtoverlay=dwc2$' /boot/firmware/config.txt || {
		echo "dtoverlay=dwc2" | tee -a /boot/firmware/config.txt
	}
	[ -f /etc/modules-load.d/dwc2.conf ] || {
		echo "dwc2" | tee /etc/modules-load.d/dwc2.conf
	}
	ok "USB controller overlay done"
}

make_usbstick() {
	# Make a filesystem on a file
	[ -e "${usbstick}" ] || {
		truncate -s 16G "${usbstick}"
		mkdosfs "${usbstick}" -F 32 --mbr=yes -n PIMASSS
	}
	# Create the mountpoint
	[ -d "${mountpoint}" ] || {
		mkdir -pv "${mountpoint}"
		chmod -v +w "${mountpoint}"
	}
	# Add mount to fstab
	grep -q "${usbstick}" /etc/fstab || {
		echo "${usbstick} ${mountpoint} vfat rw,users,user,exec,umask=000 0 0" | tee -a /etc/fstab
		systemctl daemon-reload
	}
	# Mount filesystem
	mountpoint -q "${mountpoint}" || {
		mount "${mountpoint}"
	}
	ok "USB stick (size=${size}) created and mounted"
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
