#!/bin/bash

POSITONAL_ARGS=()

while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
			echo "Usage: icepak <command> [OPTIONS]"
			echo ""
			echo "Commands:"
			echo "  build         Build the application"
			echo "Options:"
			echo "  -h, --help     Print this help message and exit"
			exit 0
			;;
		*)
			POSITONAL_ARGS+=("$1")
			shift
			;;
	esac
done

set -- "${POSITONAL_ARGS[@]}"

COMMAND=$1
shift

if [ -z "$COMMAND" ]; then
	echo "No command specified"
	exit 1
fi

if [ "$COMMAND" == "build" ]; then

	if [ -z "$1" ]; then
		if [ -f "ipak.yaml" ]; then
			RECIPE="ipak.yaml"
		else
			echo "No recipe specified"
			exit 1
		fi
	else
		RECIPE="$1"
		if [ ! -f "$RECIPE" ]; then
			echo "Recipe not found: $RECIPE"
			exit 1
		fi
		shift
	fi

	
fi