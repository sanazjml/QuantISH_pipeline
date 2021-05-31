#!/bin/sh

if [ $# -ne 3 ]; then
	echo "Usage: $0 filled.png segmented.png output.csv" >&2
	exit 1
fi
       

path="$(dirname "$0")"
"$path/matlab-run.py" "$path/classify_run.m" src_spot="$1" src_segmented="$2" dest="$3" 
