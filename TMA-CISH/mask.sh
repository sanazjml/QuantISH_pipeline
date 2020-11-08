#!/bin/sh

if [ $# -ne 3 ]; then
	echo "Usage: $0 spot.png channel.png out.png" >&2
	exit 1
fi
       

path="$(dirname "$0")"
"$path/matlab-run.py" "$path/mask_run.m" src_spot="$1" src_channel="$2" dest="$3"
