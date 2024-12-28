#!/bin/bash

SELF="$(readlink -f "$0")"
SELF_DIR="$(dirname "$SELF")"

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

function config_option_exists() {
	if [ ! -f "$SELF_DIR/.config/$1" ]; then
		return 1
	fi

	return 0
}

function non_existent_config_option_error() {
	display_error "Missing required config option: $1. This is a problem with the application. Please contact the application's developer and report this error message to them."
	return 1
}

function bwrap_bind_mount_root() {
	local ARGS
	ARGS=""
	for d in /*; do
		ARGS="$ARGS --dev-bind $d $d"
	done

	echo "$ARGS"
}

function bwrap_bind_app() {
	local ARGS
	ARGS=""
	for d in $SELF_DIR/*; do
		if [ "$d" == "/lib" ] || [ "$d" == "/lib64" ]; then
			continue
		fi
		ARGS="$ARGS --dev-bind $d $d"
	done

	echo "$ARGS"
}

config_option_exists entrypoint || exit $(non_existent_config_option_error entrypoint)

entrypoint="$(get_config_option entrypoint)"

bwrap $(bwrap_bind_mount_root) $(bwrap_bind_app) -- "$entrypoint" "$@"