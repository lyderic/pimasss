#!/bin/bash

usbstick="/usbstick.bin"

main() {
	[[ "${1}" == "-u" ]] && {
		unload
		return
	}
	lsmod | grep -q g_mass_storage || {
		modprobe g_mass_storage file="${usbstick}" stall=0 ro=0
	}
}

unload() {
	modprobe -r g_mass_storage
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

main ${@}
