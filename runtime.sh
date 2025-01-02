#!/bin/bash

SELF_PATH=$( readlink -f "$0" )
APPDIR=$( dirname "$SELF_PATH" )

L_LIBRARY_PATH=""

function error() {
	if which zenity > /dev/null; then
		zenity --error --text "$1"
	else
		echo "$1"
	fi
}

function bind_root() {
	local ARGS
	ARGS=""

	for dir in /*; do
		ARGS="$ARGS --dev-bind $dir $dir"
	done

	echo "$ARGS"
}

function bind_app() {
	local ARGS
	ARGS=""

	for dir in "$APPDIR"/*; do
		ARGS="$ARGS --dev-bind $dir $(basename "$dir")"
	done

	echo "$ARGS"
}

function get_config_option() {
	if [ -f "$APPDIR/.config/$1" ]; then
		cat "$APPDIR/.config/$1"
		return 0
	else
		return 1
	fi

	return 1
}

function environment() {
	while IFS='=' read -r -d '' n v; do
    	if [ "$n" == "LD_LIBRARY_PATH" ] || [ "$n" == "_" ]; then
			continue
		fi

		if [ "${n:0:4}" == "XDG_" ]; then
			printf -- '--setenv '%s' '%s'\n' "$n" "$v"
		fi
	done < <(env -0)

	if get_config_option library_path > /dev/null; then
		echo "AAAAHHHHH" >&2
	fi
	L_LIBRARY_PATH="$(get_config_option library_path || echo "$LD_LIBRARY_PATH")"
	echo "--setenv LD_LIBRARY_PATH '$L_LIBRARY_PATH'"
}

bwrap \
	$(bind_root) \
	$(bind_app) \
	$(environment) \
	$(get_config_option entrypoint) "$@"