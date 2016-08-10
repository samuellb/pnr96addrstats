#!/bin/sh

useragent='AddrStatsBot/0.1.1 (https://osm.kodafritt.se/pnr96addrstats/; samuel@kodafritt.se)'
apiurl='http://overpass-api.de/api'

overpass() {
    wget --no-verbose -U "${useragent}" "-Odata/$1" "$apiurl/$2"
}
