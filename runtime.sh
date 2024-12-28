#!/bin/bash

set -eo pipefail

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