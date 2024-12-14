#!/bin/sh

POSITIONAL_ARGS=()

build_file=""

while [[ $# -gt 0 ]]; do
  case $1 in
	-h | --help)
		echo "Usage: $0 --file <build_file>"
		shift
		exit 0
		;;
	--file)
	  build_file="$2"
	  shift
	  shift
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

if [ -z "$build_file" ]; then
	echo "Usage: $0 --file <build_file>"
	exit 1
fi

if [ ! -f "$build_file" ]; then
	echo "$build_file path not found"
	exit 1
fi

output_file=""
distro=""
created_output_file="false"

while IFS='' read -r line; do
	if [ -z "$line" ]; then
		continue
	fi
	if [ "${line:0:1}" == "#" ]; then
		continue
	fi

	if [ "${line:0:2}" == "> " ]; then
		output_file="${line:2:-1}"
		continue
	fi

	if [ "${line:0:2}" == "< " ]; then
		distro="${line:2:-1}"
		continue
	fi

	if [ -z "$output_file" ] || [ -z "$distro" ]; then
		echo "You must specify an output file and distro before other commands!"
		exit 1
	fi

	if [ "$created_output_file" == "false" ]; then
		./dist-to-ipak.sh "$distro" "$output_file" "$output_file"
		created_output_file="true"
	fi

done < "$build_file"