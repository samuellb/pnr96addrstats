#!/bin/bash

. env.sh

objid=$(awk '{ print $3, $2 }' < data/kommuner.csv| grep "^$1" | awk '{ print $2 }')

areaid=$((3600000000 + objid))
overpass "roads_$1.csv" '/interpreter?data=[out:csv(::"type",::"id",name)];way["name"]["highway"](area:'$areaid');out tags qt;&bbox='${swedenbbox:?}
