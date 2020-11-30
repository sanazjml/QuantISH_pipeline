#!/bin/sh

if [ $# -ne 2 ]; then
	echo "Usage: $0 file.csv key" >&2
	exit 1
fi

src="$1"
key="$2"

cat "$src" | sed '1d' | while IFS="$(printf '\t')" read key1 val1; do
	if [ "$key1" = "$key" ]; then
		echo "$val1"
		break
	fi
done
