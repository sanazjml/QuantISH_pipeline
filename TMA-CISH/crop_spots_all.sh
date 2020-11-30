#!/bin/sh

root=''  #The directory in which the csv file of bounding box coordinated has been saved (cropTMA.m output)

mrxsdump='mrxsdump.py'


FILES=$(find "$root" -name '*.csv')
cat $FILES | while IFS="$(printf '\t')" read path spot x y w h; do
        case="$(basename "$path")"
        spotname="$( printf '%03d' "$spot" )"
        layer='HIER_0_VAL_0'
        dest=$case/$spotname/

           mkdir -p "$dest"
          "$mrxsdump" -g "$layer" -r -P -c "${w}x${h}+${x}+${y}" -o "$dest" "$path"
           mv "$case/$spotname/$layer.png" "$case/${layer}_SPOT_$spotname.png"
           rmdir -p "$dest"


done
