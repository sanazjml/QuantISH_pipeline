#!/bin/sh

if [ $# -ne 5 ]; then
	echo "Usage: $0 crop1.png crop2.png crop3.png crop4.png img.png" >&2
	exit 1
fi
       

path="$(dirname "$0")"
"$path/matlab-run.py" "$path/merge_run.m" src_spot1="$1"  src_spot2="$2" src_spot3="$3" src_spot4="$4" dest="$5" 

