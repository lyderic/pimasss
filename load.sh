#!/bin/bash

usbstick="/usbstick.bin"

main() {
	validate
	status
	[[ "${1}" == "-u" ]] && {
		unload
		return
	}
	if lsmod | grep -q g_mass_storage ; then
		echo -ne "\e[33mUSB Mass Storage module already loaded. Unload? [y/N]? \e[m"
		read -t 3 yesno ; [[ "${yesno,,}" =~ ^(y|yes)$ ]] || return
		unload
	else
		load
	fi
}

status() {
	lsmod | grep g_mass_storage
}

load() {
	if sudo modprobe g_mass_storage file="${usbstick}" stall=0 ro=0 ; then
		echo -e "\e[32mUSB Mass Storage module loaded successfully\e[m"
	else
		echo -e "\e[31mUSB Mass Storage module failed to load!!!\e[m"
	fi
}

unload() {
	if sudo modprobe -r g_mass_storage ; then
		echo -e "\e[32mUSB Mass Storage module successfully unloaded\e[m"
	else
		echo -e "\e[31mUSB Mass Storage module failed to unload!!!\e[m"
	fi
}

validate() {
	# The user of this script needs to have root privs
	sudo -l >/dev/null 2>&1 || {
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
