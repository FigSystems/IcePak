#!/bin/sh

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
	-h | --help)
		echo "Usage: $0 --file <ipakfile>"
		shift
		exit 0
		;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters