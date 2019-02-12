#!/bin/sh

# install-ga.sh - install VirtualBox Guest Additions under Kali


set -o nounset

color_red=1
color_green=2
color_blue=4

iso='/usr/share/virtualbox/VBoxGuestAdditions.iso'

program_name="$(basename -- "$0")" || exit 1


# Because POSIX echo is broken ...
echo()
{
	printf '%s\n' "$*"
}


safe_tput()
{
	if test -t 1; then
		tput "$@"
	fi
}


colored_message()
{
	safe_tput bold
	safe_tput setaf "$1"
	echo "${program_name}: $2"
	safe_tput sgr0
}


error()
{
	colored_message "${color_red}" "${1:-an error occurred}" >&2
	exit 1
}


info()
{
	colored_message "${color_blue}" "$1"
}


green_info()
{
	colored_message "${color_green}" "$1"
}


on_exit()
{
	safe_tput sgr0
	if mountpoint -q "${tmp_dir}"; then
		sudo umount "${tmp_dir}"
	fi
	if test -d "${tmp_dir}"; then
		rmdir "${tmp_dir}"
	fi
}


on_signal()
{
	echo
	exit 1
}


trap on_exit EXIT
trap on_signal HUP INT QUIT PIPE TERM

tmp_dir="$(mktemp -d)" || error

info 'installing packages ...'
sudo apt-get update || error
sudo apt-get install -y --only-upgrade linux-image-amd64 || error
sudo apt-get install -y linux-headers-amd64 \
                        virtualbox-guest-additions-iso || error

info 'mounting the guest additions iso ...'
sudo mount "${iso}" "${tmp_dir}" || error

info 'installing guest additions ...'
(
	cd "${tmp_dir}" || exit 1
	# Note that we ignore the exit status of VBoxLinuxAdditions.run
	# because it usually "fails" anyway, even if it succeeds ...
	sudo bash 'VBoxLinuxAdditions.run'
	exit 0
) || error

info 'unmounting the guest additions iso ...'
sudo umount "${tmp_dir}" || error

green_info 'completed successfully'
green_info 'the system needs to be restarted'
green_info 'enter "y" if you want to restart now'

read reply
if echo "${reply}" | grep -q '^ *[yY] *$'; then
	sudo shutdown -r now || error
fi

exit 0
