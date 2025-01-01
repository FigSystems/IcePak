#!/bin/bash

export RESET="$(tput sgr0)"
export BLACK="$(tput setaf 0)"
export RED="$(tput setaf 1)"
export GREEN="$(tput setaf 2)"
export YELLOW="$(tput setaf 3)"
export BLUE="$(tput setaf 4)"
export MAGENTA="$(tput setaf 5)"
export CYAN="$(tput setaf 6)"
export WHITE="$(tput setaf 7)"
export BRIGHT_BLACK="$(tput setaf 8)"
export BRIGHT_RED="$(tput setaf 9)"
export BRIGHT_GREEN="$(tput setaf 10)"
export BRIGHT_YELLOW="$(tput setaf 11)"
export BRIGHT_BLUE="$(tput setaf 12)"
export BRIGHT_MAGENTA="$(tput setaf 13)"
export BRIGHT_CYAN="$(tput setaf 14)"
export BRIGHT_WHITE="$(tput setaf 15)"

set -eo pipefail

POSITONAL_ARGS=()
VERBOSE=false

while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
			echo "Usage: icepak <command> [OPTIONS]"
			echo ""
			echo "Commands:"
			echo "  build         Build the application"
			echo "Options:"
			echo "  -h, --help     Print this help message and exit"
			echo "  -v, --verbose  Print verbose output"
			exit 0
			;;
		-v|--verbose)
			VERBOSE=true
			shift
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

function verify_recipe() {
	if [ $(yq 'has("App")' "$1") != "true" ]; then
		echo "Invalid recipe: $1"
		echo "Missing App section"
		exit 1
	fi

	if [ $(yq 'has("Recipe")' "$1") != "true" ]; then
		echo "Invalid recipe: $1"
		echo "Missing Recipe section"
		exit 1
	fi

	if [ $(yq '.App | has("Name")' "$1") != "true" ]; then
		echo "Invalid recipe: $1"
		echo "Missing App.Name"
		exit 1
	fi

	if [ $(yq 'has("Config")' "$1") != "true" ]; then
		echo "Invalid recipe: $1"
		echo "Missing Config section"
		exit 1
	fi

	if [ $(yq '.App | has("OutputDirectory")' "$1") != "true" ]; then
		echo "Invalid recipe: $1"
		echo "Missing App.OutputDirectory"
		exit 1
	fi

	if [ ! $(yq '.Config.[] | has("entrypoint")' | grep -q "true") ]; then

		echo	"${RED}Error: Entrypoint not set!"
		echo
		echo 	"${ORANGE}Please add the entrypoint to the config using:"
		echo
		echo	"${GREEN}+ Config:
+   - entrypoint: /path/to/entrypoint${RESET}"
		exit 1
}

function init() {
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
	fi

	RECIPE="$(readlink -f "$RECIPE")"

	if [ -z "$(which yq)" ]; then
		echo "yq is not installed"
		echo "Please install yq: https://github.com/mikefarah/yq"
		exit 1
	fi

	verify_recipe "$RECIPE"

	APP_NAME=$(yq '.App.Name' "$RECIPE")
	OUTPUT_DIRECTORY=$(yq '.App.OutputDirectory' "$RECIPE")
	BUILD_TYPE="$(yq '.Type.Type' "$RECIPE")"

	if [ "$VERBOSE" == "true" ]; then
		echo "Recipe: $RECIPE"
		echo "App.Name: $APP_NAME"
		echo "App.OutputDirectory: $OUTPUT_DIRECTORY"
		echo "Type: $BUILD_TYPE"
	fi
}

init $1

function build() {
	build_dir=$(mktemp -d)
	ln -sfT "$(readlink -f "$OUTPUT_DIRECTORY")" "$build_dir/AppDir"

	if [ "${BUILD_TYPE:0:3}" == "tar" ]; then
		TAR_SUBTYPE="${BUILD_TYPE:3}"

		case $TAR_SUBTYPE in
			.gz)
				tar xf "$RECIPE" -C "$build_dir"

}



if [ "$COMMAND" == "build" ]; then
	if [ "$VERBOSE" == "true" ]; then
		echo "Building $APP_NAME"
	fi
	build "$RECIPE"
fi