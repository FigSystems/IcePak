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

SELF=$(readlink -f "$0")
SELF_DIR=$(dirname "$SELF")



# set -eo pipefail

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

function config_error() {
	echo "${RED}Error: $1${RESET}"
	echo
	echo "${YELLOW}$2${RESET}"
	echo
	echo "${GREEN}$3${RESET}"
}


function invalid_recipe_error() {
	echo "${RED} - $1${RESET}"
}


function verify_recipe() {
	ERROR="false"


	if [ $(yq 'has("App")' "$1") != "true" ]; then
		invalid_recipe_error "Missing App section"
		ERROR="true"
	fi

	if [ $(yq 'has("Recipe")' "$1") != "true" ]; then
		invalid_recipe_error "Missing Recipe section"
		ERROR="true"
	fi

	if [ $(yq '.App | has("Name")' "$1") != "true" ]; then
		invalid_recipe_error "Missing App.Name"
		ERROR="true"
	fi

	if [ $(yq 'has("Config")' "$1") != "true" ]; then
		invalid_recipe_error "Missing Config section"
		ERROR="true"
	fi

	if [ $(yq '.App | has("OutputDirectory")' "$1") != "true" ]; then
		invalid_recipe_error "Missing App.OutputDirectory"
		ERROR="true"
	fi

	if ! $(yq '.Config.[] | has("EntryPoint")' "$1" | grep -q "true"); then
		invalid_recipe_error "Missing Config.EntryPoint. Should be e.g. /App/your_app"
		ERROR="true"
	fi

	if ! $(yq '.Config.[] | has("Version")' "$1" | grep -q "true"); then
		invalid_recipe_error "Missing Config.Version"
		ERROR="true"
	fi

	if ! $(yq '.Config.[] | has("Description")' "$1" | grep -q "true"); then
		invalid_recipe_error "Missing Config.Description"
		ERROR="true"
	fi

	if ! $(yq '.Config.[] | has("Developer")' "$1" | grep -q "true"); then
		invalid_recipe_error "Missing Config.Developer"
		ERROR="true"
	fi

	if ! $(yq '.Config.[] | has("Architecture")' "$1" | grep -q "true"); then
		invalid_recipe_error "Missing Config.Architecture. e.g. x86_64 or arm64"
		ERROR="true"
	fi

	if [ "$ERROR" == "true" ]; then
		echo "${YELLOW}Invalid recipe: $1${RESET}"
		echo "${YELLOW}Please corect the previous errors and try again${RESET}"
		exit 1
	fi
}

function init() {
	if [ -z "$1" ]; then
		if [ -f "icepak.yml" ]; then
			RECIPE="icepak.yml"
		elif [ -f "ipak.yaml" ]; then
			RECIPE="ipak.yaml"
		elif [ -f "ipak.yml" ]; then
			RECIPE="ipak.yml"
		elif [ -f "icepak.yaml" ]; then
			RECIPE="icepak.yaml"
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
	ICON=$(readlink -f $(yq '.App.Icon' "$RECIPE"))
	DESKTOP_FILE=$(readlink -f $(yq '.App.DesktopFile' "$RECIPE"))

	if [ "$VERBOSE" == "true" ]; then
		echo "Recipe: $RECIPE"
		echo "App.Name: $APP_NAME"
		echo "App.OutputDirectory: $OUTPUT_DIRECTORY"
		echo "App.Icon: $ICON"
		echo "App.DesktopFile: $DESKTOP_FILE"
	fi
}

function get_recipe_step_indices() {
	STEP_INDICES=$(yq '.Recipe.[] | key' "$1" | tr '\n' ' ')

	echo "$STEP_INDICES"
}

function get_config_indices() {
	CONFIG_INDICES=$(yq '.Config.[] | key' "$1" | tr '\n' ' ')

	echo "$CONFIG_INDICES"
}

function get_libraries() {
	local LIB
	LIB=""
	LIBS=""
	for i in "$@"; do
		LIB2="$(ldd "$i" | cut -d " " -f 3 | tr '\n' ' ' | awk '{$1=$1};1')"
		# echo "$LIB" >&2

		for lib in $LIB2; do
			if [ "$lib" == "not" ]; then
				continue # not found
			fi
			if [ ! -f "$lib" ]; then
				echo "${YELLOW}Warning: Library not found: $lib${RESET}!" >&2
				continue # not found
			fi
			LIBS="$LIBS $lib"
		done
	done

	LIBS=$( set -f; printf "%s\n" $LIBS | sort -u | paste -sd" " )

	echo "$LIBS"
}

function build() {
	REPO="$(pwd)"
	PROJECT_ROOT="$REPO"
	PROJECT="$REPO"
	REPO_ROOT="$REPO"
	REPO_DIR="$REPO"
	PROJECT_DIR="$REPO"
	SRC_DIR="$REPO"
	SRC="$REPO"

	echo "Building $APP_NAME"

	if [ -d "$OUTPUT_DIRECTORY" ]; then
		rm -rf "$OUTPUT_DIRECTORY"
	fi

	mkdir -p "$OUTPUT_DIRECTORY"

	build_dir="$(mktemp -d)"
	ln -sfT "$(readlink -f $OUTPUT_DIRECTORY)" "$build_dir/AppDir"

	cd "$build_dir"
	previous_dir="$(pwd)"

	STEP_INDICES=$(get_recipe_step_indices "$RECIPE")

	for STEP_INDEX in $STEP_INDICES; do
		if [ "$VERBOSE" == "true" ]; then
			echo "Step: $STEP_INDEX"
		fi

		STEP_NAME=$(yq ".Recipe.$STEP_INDEX.[] | key" "$RECIPE")
		echo "===== ${BRIGHT_GREEN}$STEP_NAME${RESET} ======"

		TYPE="standard"
		STEP=$(yq ".Recipe.$STEP_INDEX" "$RECIPE")

		if $(yq ".Recipe.$STEP_INDEX.[] | has(\"type\")" "$RECIPE" | grep -q true); then
			TYPE=$(yq ".Recipe.$STEP_INDEX.[].type" "$RECIPE")
		fi

		if $(yq ".Recipe.$STEP_INDEX.[] | has(\"workdir\")" "$RECIPE" | grep -q true); then
			WORKDIR=$(yq ".Recipe.$STEP_INDEX.[].workdir" "$RECIPE")
			if [ ! -d "$WORKDIR" ]; then
				mkdir -p "$WORKDIR"
			fi
			cd "$WORKDIR"
		fi

		if [ $TYPE == "libraries" ] && $(yq ".Recipe.$STEP_INDEX.[] | has(\"files\")" "$RECIPE" | grep -q true); then
			FILES=$(yq ".Recipe.$STEP_INDEX.[].files" "$RECIPE")
			mkdir -p "$build_dir/AppDir/lib/"
			cp --no-clobber $(get_libraries $FILES) "$build_dir/AppDir/lib/"
		fi

		if $(yq ".Recipe.$STEP_INDEX[] | has(\"script\")" "$RECIPE" | grep -q true); then
			SCRIPT=$(yq ".Recipe.$STEP_INDEX.[].script" "$RECIPE")
			if [ "$VERBOSE" == "true" ]; then
				echo "Directory: $(pwd)"
				echo "--------------"
				echo "$SCRIPT"
				echo "--------------"
			fi
			eval "$SCRIPT"
		fi

		cd "$build_dir"
	done


	CONFIG_INDICES=$(get_config_indices "$RECIPE")
	mkdir -p "$build_dir/AppDir/.config"

	for CONFIG_INDEX in $CONFIG_INDICES; do
		if [ "$VERBOSE" == "true" ]; then
			echo "Config: $CONFIG_INDEX"
		fi

		CONFIG_NAME=$(yq ".Config.$CONFIG_INDEX.[] | key" "$RECIPE")
		CONFIG_VALUE=$(yq ".Config.$CONFIG_INDEX.$CONFIG_NAME" "$RECIPE")

		if [ "$VERBOSE" == "true" ]; then
			echo "$CONFIG_NAME = $CONFIG_VALUE"
		fi

		echo "$CONFIG_VALUE" > "$build_dir/AppDir/.config/$CONFIG_NAME"
	done

	echo "$APP_NAME" > "$build_dir/AppDir/.config/APP_NAME"

	cp "$SELF_DIR/runtime.sh" "$build_dir/AppDir/AppRun"
	chmod +x "$build_dir/AppDir/AppRun"

	# Check if yml file has a .Final.script (Untested)
	if $(yq ".Final.[] | has(\"script\")" "$RECIPE" | grep -q true); then
		SCRIPT=$(yq ".Final.script" "$RECIPE")
		if [ "$VERBOSE" == "true" ]; then
			echo "Directory: $(pwd)"
			echo "--------------"
			echo "$SCRIPT"
			echo "--------------"
		fi
		eval "$SCRIPT"
	fi

	rm "$build_dir/AppDir"
	rm -rf "$build_dir"
}

init "$1"

if [ "$COMMAND" == "build" ]; then
	build
else
	echo "Unknown command: $COMMAND" >&2
	exit 1
fi