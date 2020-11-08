#!/bin/sh

if [ $# -ne 5 ]; then
	echo "Usage: $0 img.tif crop1.png crop2.png crop3.png crop4.png" >&2
	exit 1
fi
       

path="$(dirname "$0")"
"$path/matlab-run.py" "$path/crop_run.m" src_spot="$1" dest1="$2" dest2="$3" dest3="$4" dest4="$5"
