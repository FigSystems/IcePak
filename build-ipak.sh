#!/bin/bash

POSITIONAL_ARGS=()

build_file=""
distro_file=""

while [[ $# -gt 0 ]]; do
  case $1 in
	-h | --help)
		echo "Usage: $0 <build_file>"
		echo "-h, --help      show this help text"
		echo "--distro-file     (optional) path to distro file"
		shift
		exit 0
		;;
	--distro-file)
		distro_file="$2"
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

function file_ends_with_newline() {
    [[ $(tail -c1 "$1" | wc -l) -gt 0 ]]
}

if [ -z "$1" ]; then
	echo "Usage: $0 <build_file>"
	exit 1
fi

build_file="$1"

if [ ! -f "$build_file" ]; then
	echo "$build_file path not found"
	exit 1
fi

if ! file_ends_with_newline "$build_file"; then
	echo "build file must end with a newline"
	read -p "Would you like to add one? (y/N) " REPLY
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo >> "$build_file"
	else
		exit 1
	fi
fi

output_path=""
distro=""
created_output_dir="false"
name="AppRun"
alt_args=()

while IFS='' read -r line; do
	if [ -z "$line" ]; then
		continue
	fi

	if [ "${line:0:1}" == "#" ]; then
		continue
	fi

	if [ "${line:0:2}" == "> " ]; then
		output_path="${line:2}"
		output_path="$(realpath $output_path)"
		mkdir -p "$output_path"
		echo "Output file: $output_path"


		if [ -n "$distro_file" ]; then
			if [ -f "$distro_file" ]; then
				echo "Distro file: $distro_file"
				rm -rf "$output_path"
				mkdir -p "$output_path"
				tar -xzf "$distro_file" -C "$output_path"
				created_output_dir="true"
			else
				echo "Distro file not found: $distro_file"
				exit 1
			fi
		fi
		continue
	fi

	if [ "${line:0:2}" == "< " ]; then
		distro="${line:2}"
		echo "Distro: $distro"
		continue
	fi

	if [ "${line:0:2}" == "& " ]; then
		alt_arg="${line:2}"
		alt_args+=( "$alt_arg" )
		continue
	fi

	if [ "${line:0:6}" == "Name: " ]; then
		name="${line:6}"
		echo "Name: $name"
		continue
	fi

	if [ -z "$output_path" ] || [ -z "$distro" ]; then
		echo "You must specify an output file and distro before other commands!"
		exit 1
	fi

	if [ "$created_output_dir" == "false" ]; then
		# Fetch distro $distro and output to $output_path
		tmp_output=$(mktemp)
		wget "https://github.com/FigSystems/IcePak/releases/latest/download/$distro.tgz" -O $tmp_output
		rm -rf $output_path
		mkdir -p $output_path
		tar -xzf $tmp_output -C $output_path

		if [ $? -ne 0 ]; then
			echo "Failed to fetch distro $distro"
			echo "This could be because the distro doesn't exist or you don't have internet access."
			exit 243
		fi
		created_output_dir="true"
	fi

	${output_path}/.run.sh --ipak-build-mode "${alt_args[@]}" $line
	if [ $? -ne 0 ]; then
		exit 1
	fi

	# "$output_path" "$line"

done < "$build_file"

ln -sfT "$output_path/.run.sh" "$output_path/$name"