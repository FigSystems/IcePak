#!/bin/bash

# To be run from inside the IPak's directory.
# $PWD
# |- rootfs
# |- icon
# \- app.desktop

cmd="/AppRun"
POSITIONAL_ARGS=()
ALL_ARGS=()
user_cwd=""
extract_icon=""
cmd="/AppRun"
build_mode="false"

while [[ $# -gt 0 ]]; do
  case $1 in
	--ipak-help)
		echo "Usage: $0 [arguments to contained command...]"
		echo "--ipak-help         show this help text"
		echo "--ipak-shell        run an interactive shell in the bundle"
		shift
		exit 0
		;;
	--ipak-shell)
		echo "Running interactive shell..."
		cmd="/bin/sh"
		shift
		;;
	--ipak-build-mode)
		build_mode="true"
		shift
		;;
	--ipak-cwd)
		if [ -z "$2" ]; then
			echo "Usage: $0 --ipak-cwd directory"
			exit 1
		fi
		user_cwd="$2"
		shift
		shift
		;;
    -*|--*)
	  ALL_ARGS+=("$1")
	  shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
	  ALL_ARGS+=("$1")
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

cmd="$cmd ${ALL_ARGS[@]}"

if [ "$1" == "shell" ]; then
	cmd="${ALL_ARGS[@]:1}"
fi
if [ "$1" == "set-entrypoint" ]; then
	if [ -z "$2" ]; then
		echo "Usage: $0 set-entrypoint path/to/executable"
		exit 1
	fi
	cmd="echo '#!/bin/sh' > /AppRun && echo '${ALL_ARGS[@]:1}' > /AppRun && chmod +x /AppRun"
fi
if [ "$1" == "cp" ]; then
	if [ -z "$2" ]; then
		echo "Usage: $0 cp source dest"
		exit 1
	fi
	cmd="cp -r '$(realpath $2)' '$3'"
fi