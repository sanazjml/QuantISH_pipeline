#!/bin/sh

set -e

if [ $# -ne 2 ]; then
	echo "Usage: $0 input.png output.png" >&2
	exit 1
fi

# TODO: when you run full dataset, comment out this part to have 
# empty segmentation instead of re-running the cellprofiler
# then run ./take_segmented.sh to copy already run cellprofiler
# results over the empty segmentation results

# TODO: then delete this line when this is done for all data

#exec "$(dirname "$0")/segment_null.sh" "$@"

src="$1"
dest="$2"

abspath() {
	case "$1" in
	/*)
		echo "$1"
		;;
	*)
		echo "$PWD/$1"
		;;
	esac
}

# get temp directory
work_dir="$(mktemp -d /tmp/CellProfiler.XXXXX)"

# set up paths
in_dir="$work_dir/in/"
in_file="$in_dir/$(basename "$src")"
out_dir="$work_dir/out/"
out_file="$out_dir/$(basename "$src")"

# create working directory stuff
mkdir -p "$in_dir" "$out_dir"
cp "$src" "$in_file"

# set Java path
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"

# run CellProfiler
# WARNING: this will crap out the results into cd
path="$(abspath "$(dirname "$0")")"
(cd "$out_dir" && "$path/CellProfiler.py" -c -r -p "$path/segment.cpproj" -i "$in_dir")

# clean up
mv "$out_file" "$dest"
rm "$in_file"
rmdir "$in_dir" "$out_dir" "$work_dir"
