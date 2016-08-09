#!/bin/bash

set -e
set -u

export LC_ALL=C.UTF-8
IFS=$(printf '\t')
export IFS

echo "scbnummer,kortnamn,missing_class,missing_ratio,unknown_class,unknown_ratio" > jekyll/_data/kommuner_overview.csv

while read objtype objid scbnummer kortnamn langnamn pnr_missing pnr_total pnr_unknown osm_total; do
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$scbnummer" "$objid" "$kortnamn" "$langnamn" "$pnr_missing" "$pnr_total" "$pnr_unknown" "$osm_total"
done < data/kommuner_data.csv | sort -n | while read scbnummer objid kortnamn langnamn pnr_missing pnr_total pnr_unknown osm_total; do
    # Kvar %
    if [ "$pnr_total" != 0 ]; then
        missing_ratio=$((pnr_missing * 100 / pnr_total))
    else
        missing_ratio="-"
    fi
    # Okända %
    if [ "$osm_total" != 0 ]; then
        unknown_ratio=$((pnr_unknown * 100 / osm_total))
    else
        unknown_ratio="-"
    fi
    missing_class=""
    case "$missing_ratio" in
    0) missing_class="rg";;
    1|2|3|4|5|6|7|8|9) missing_class="r9";;
    1?) missing_class="r8";;
    2?) missing_class="r7";;
    3?) missing_class="r6";;
    4?) missing_class="r5";;
    5?) missing_class="r4";;
    6?) missing_class="r3";;
    7?) missing_class="r2";;
    8?) missing_class="r2";;
    9?|???*) missing_class="r1";;
    esac
    unknown_class=""
    case "$unknown_ratio" in
    0) unknown_class="rg";;
    1|2|3|4|5|6|7|8|9) unknown_class="r9";;
    1?) unknown_class="r8";;
    2?) unknown_class="r7";;
    3?) unknown_class="r6";;
    4?) unknown_class="r5";;
    5?) unknown_class="r4";;
    6?) unknown_class="r3";;
    7?) unknown_class="r2";;
    8?) unknown_class="r2";;
    9?|???*) unknown_class="r1";;
    esac

    echo "$scbnummer,$kortnamn,$missing_class,$missing_ratio,$unknown_class,$unknown_ratio"
done >> jekyll/_data/kommuner_overview.csv
