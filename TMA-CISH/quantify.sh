#!/bin/sh

if [ $# -ne 5 ]; then
	echo "Usage: $0 spot.png channel.png segmented.png classes.csv output.csv" >&2
	exit 1
fi

path="$(dirname "$0")"
"$path/matlab-run.py" "$path/quantify_run.m" src_spot="$1" src_channel="$2" src_segmented="$3" src_classes="$4" dest="$5"
