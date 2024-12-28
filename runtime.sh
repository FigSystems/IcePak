#!/bin/bash

SELF="$(readlink -f "$0")"
SELF_DIR="$(dirname "$SELF")"

trap "exit 1" TERM
export TOP_PID=$$

function display_error() {
	if which zenity > /dev/null; then
		zenity --error --text="$1"
	else
		echo "E: $1"
	fi
}

function display_info() {
	if which zenity > /dev/null; then
		zenity --info --text="$1"
	else
		echo "I: $1"
	fi
}

function display_warning() {
	if which zenity > /dev/null; then
		zenity --warning --text="$1"
	else
		echo "W: $1"
	fi
}

function get_config_option() {
	if [ ! -f "$SELF_DIR/.config/$1" ]; then
		return 1
	fi

	cat "$SELF_DIR/.config/$1"
	return 0
}

function get_required_config_option() {
	local VALUE
	VALUE=$(get_config_option "$1")
	get_config_option "$1"

	if [ $? != 0 ]; then
		display_error "Missing required config option: $1. This is a problem with the application. Please contact the application's developer and report this error message to them."
	fi

	echo "$VALUE"
}

zenity --info --text="Entrypoint: $(get_required_config_option entrypoint)"