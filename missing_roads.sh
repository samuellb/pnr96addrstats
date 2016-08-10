#!/bin/sh -eu

export LC_ALL=C.UTF-8
IFS=$(printf '\t')
export IFS
tab="$(printf '\t')"

###
### Get a list of all municipality relations in Sweden
###
while read objtype objid scbnummer kortnamn langnamn; do
    echo "$kortnamn"
done < data/kommuner.csv | tr '[a-zåäöéà]' '[A-ZÅÄÖÉÀ]' | sort | uniq > data/kommuner.txt

###
### Builds reports for a municipality, and outputs a tab-separated line with statistics
###
process_data() {
    objtype=$1
    objid=$2
    scbnummer=$3
    kortnamn=$4
    langnamn=$5
    uppername=$(echo "$kortnamn" | tr '[a-zåäöéà]' '[A-ZÅÄÖÉÀ]')

    while read objtype objid roadname; do
        echo "$roadname"
    done < data/roads_${scbnummer}.csv | tr '[a-zåäöéà]' '[A-ZÅÄÖÉÀ]' | sort | uniq > data/roads_${scbnummer}_unique.txt

    outfile="jekyll/_missing_roads/$scbnummer.md"
    cat > "$outfile" <<EOF
---
scbnummer: ${scbnummer}
kortnamn: ${kortnamn}
title: Saknade vägar i ${langnamn}
missing_roads:
EOF
    grep -E -- "$tab$uppername$" data/pnr96_kommun.csv > data/temp1
    while read roadname kommun; do
        # Skip names starting or ending with AB (company names)
        if [ "$roadname" != "${roadname% AB}" -o "$roadname" != "${roadname#AB }" ]; then
            continue
        fi
        # Look for missing road name in OSM
        if ! grep -qE -- "^$roadname$" data/roads_${scbnummer}_unique.txt; then
            echo "  - ${roadname}" >> "$outfile"
        fi
    done < data/temp1
    rm data/temp1
    echo "---" >> "$outfile"
}

while read objtype objid scbnummer kortnamn langnamn; do
    if [ -f "data/roads_${scbnummer}.csv" ]; then
        echo "Processing $scbnummer/$kortnamn..." >&2
        process_data "$objtype" "$objid" "$scbnummer" "$kortnamn" "$langnamn"
    fi
done < data/kommuner.csv
