#!/bin/sh -eu
#
# Copyright © 2016 Samuel Lidén Borell <samuel@kodafritt.se>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

export LC_ALL=C.UTF-8
IFS=$(printf '\t')
export IFS
mkdir -p data
tab="$(printf '\t')"

# This script builds a mapping from postal towns to municipalities


read_pnr() {
    sed -r 's/\{"streetName":"([^"]+)","postalCode":"([^"]+)","postalTown":"([^"]+)"\},/\1\t\3/' < pnr96/pnr96-streets.json
}

# Strip [ and ] lines in the JSON file, and convert to tab separated values
read_pnr | while read road city; do
    [ -z "$city" ] && continue
    printf "%s\t%s\n" "$road" "$city"
done > data/pnr96.csv

# Make a list of unique postal town names
while read road city; do
    [ -z "$city" ] && continue
    echo "$city"
done < data/pnr96.csv | sort | uniq > data/pnr96_cities.txt

# Check for postal cities which aren't also municipalities
#while read city; do
#    if ! grep -qF "$city" data/kommuner.txt; then
#        echo "$city"
#    fi
#done < data/pnr96_cities.txt > data/pnr96_non_muncipalities.txt

# Postort (postal town) --> kommun (municipality)
cp data/pnr96.csv data/pnr96_kommun.csv
while read postort kommun; do
    if [ -n "$kommun" ]; then
        sed -ir "s/\t$postort$/\t$kommun/" data/pnr96_kommun.csv
    fi
done < postort2kommun.csv
# remove temp file from sed -i
rm -f data/pnr96_kommun.csvr

