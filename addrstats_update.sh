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

nodownload=0
noprocess=0

useragent='AddrStatsBot/0.1.1 (http://samuellb.users.openstreetmap.se/pnr96addrstats/; samuel@kodafritt.se)'
export useragent

# Some definitions
apiurl='http://overpass-api.de/api'
swedenbbox=54.57,10.37,69.44,24.96

###
### Get a list of all municipality relations in Sweden
###
if [ "$nodownload" != 1 ]; then
    wget --no-verbose -U "$useragent" -Odata/kommuner.csv "$apiurl"'/interpreter?data=[out:csv(::"type",::"id","ref:scb",short_name,name)];rel["admin_level"="7"]["ref:scb"];out tags qt;&bbox='$swedenbbox
fi
while read objtype objid scbnummer kortnamn langnamn; do
    echo "$kortnamn"
done < data/kommuner.csv | tr '[a-zåäöéà]' '[A-ZÅÄÖÉÀ]' | sort | uniq > data/kommuner.txt

###
### Function to download all road names in a municipality.
###
get_data() {
    areaid=$((3600000000 + $1))
    #wget -U 'AddrStats/0.1 (+samuel@kodafritt.se)' -Odata/roads_$2.csv 'http://overpass-api.de/api/interpreter?data=[out:csv(::"type",::"id",name)];area["admin_level"="7"]["ref:scb"="'$2'"]->.searchArea;way["highway"]["name"](area.searchArea);out qt;'
    if [ "$nodownload" != 1 ]; then
        wget --no-verbose -U "$useragent" -Odata/roads_$2.csv "$apiurl"'/interpreter?data=[out:csv(::"type",::"id",name)];way["name"]["highway"](area:'$areaid');out tags qt;&bbox='$swedenbbox
    fi
}

header_html() {
    cat <<EOF
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>OSM-PNR96 Addresstäckning - $1</title>
</head>
<body>
<table>
<thead>
<tr><th colspan="3">$2</th></tr>
</thead>
<tbody>
EOF
}

footer_html() {
    cat <<EOF
</tbody>
</table>
<p>Tabellen uppdaterad: $(date +'%Y-%m-%d %H:%M %Z')</p>
<p>© <a href="http://www.openstreetmap.org/">OpenStreetMaps</a> bidragsgivare. Postortsdata kommer från "Postnummerkatalogen 1996", vars katalogskydd har upphört. Tabellen görs tillgänglig under <a href="http://opendatacommons.org/licenses/odbl/">ODbL-licensen</a>.</p>
</body>
</html>
EOF
}

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
    
    header_html "Saknade vägar i $langnamn" "Vägar som finns i PNR-96, men saknas i OSM i $kortnamn" > "data/${scbnummer}_missing_roads.html"
    pnr_missing=0
    pnr_total=0
    grep -E -- "$tab$uppername$" data/pnr96_kommun.csv > data/temp1
    while read roadname kommun; do
        # Skip names starting or ending with AB (company names)
        if [ "$roadname" != "${roadname% AB}" -o "$roadname" != "${roadname#AB }" ]; then
            continue
        fi
        # Look for missing road name in OSM
        if ! grep -qE -- "^$roadname$" data/roads_${scbnummer}_unique.txt; then
            pnr_missing=$(($pnr_missing + 1))
            echo "<tr><td><small><a href=\"../pnrlookup/lookup.php?municipality=${scbnummer}&roadname=$roadname\">[Postnr]</a></small></td><td><small><a href=\"https://www.startpage.com/do/search?q=${roadname}+${kortnamn}\">[Sök]</a></small></td><td>$roadname</td></tr>" >> "data/${scbnummer}_missing_roads.html"
        fi
        pnr_total=$(($pnr_total + 1))
    done < data/temp1
    rm data/temp1
    footer_html >> "data/${scbnummer}_missing_roads.html"
    
    header_html "Okända vägar i $langnamn" "Vägar i OSM i $kortnamn som inte finns med i PNR-96" > "data/${scbnummer}_unknown_roads.html"
    pnr_unknown=0
    osm_total=0
    while read roadname; do
        if ! grep -qE -- "^$roadname$tab$uppername$" data/pnr96_kommun.csv; then
            pnr_unknown=$(($pnr_unknown + 1))
            echo "<tr><td>$roadname</td></tr>" >> "data/${scbnummer}_unknown_roads.html"
        fi
        osm_total=$(($osm_total + 1))
    done < data/roads_${scbnummer}_unique.txt
    footer_html >> "data/${scbnummer}_unknown_roads.html"
    
    # Print row to CSV file
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$objtype" "$objid" "$scbnummer" "$kortnamn" "$langnamn" "$pnr_missing" "$pnr_total" "$pnr_unknown" "$osm_total"
}

if [ "$noprocess" != 1 ]; then
    while read objtype objid scbnummer kortnamn langnamn; do
        #if [ "$kortnamn" = "Tyresö" ]; then
        if [ "${scbnummer#01}" != "$scbnummer" -o "$scbnummer" = 2482 -o "$scbnummer" = 2518 -o "$scbnummer" = 2521 -o "$scbnummer" = 2513 -o "$scbnummer" = 2583 ]; then
            #if [ ! -e "data/roads_${scbnummer}.csv" ]; then
                echo "Processing $scbnummer/$kortnamn..." >&2
                get_data "$objid" "$scbnummer"
                process_data "$objtype" "$objid" "$scbnummer" "$kortnamn" "$langnamn"
            #fi
        fi
    done < data/kommuner.csv > data/kommuner_data.csv
fi

{

cat <<EOF
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>OSM-PNR96 Addresstäckning</title>
<style type="text/css">
tr td { background: #FFF; color #000; }
tr:nth-child(even) td { background: #eee; }
td a { display: block; text-align: right; color: #fff }
tr td.rg a { color: #000; }
tr td.rg { background: #6f6; }
tr td.r9 { background: #af6; }
tr td.r8 { background: #cf6; }
tr td.r7 { background: #df6; }
tr td.r6 { background: #ff6; }
tr td.r5 { background: #fd6; }
tr td.r4 { background: #fc6; }
tr td.r3 { background: #fb6; }
tr td.r2 { background: #fa6; }
tr td.r1 { background: #f86; }
tr td.r0 { background: #f66; }
</style>
</head>
<body>
<p>På denna sida kan man jämföra de vägnamn som finns i OpenStreetMap med de i
<a href="http://kalle.users.openstreetmap.se/pnr96/">Postnummerkatalogen från 1996</a> (tack till Karl Wettin som har fixat denna databas!). Det kan t.ex. vara bra för att hitta vägar
som saknas eller är felstavade, eller för att upptäcka områden som behöver
karteras bättre. Dock är statistiken långt ifrån perfekt, t.ex. är vissa
"vägar" egentligen inte vägar utan t.ex. namn på företag eller gårdar, som
används i addresser. Vissa vägar kan även ligga under fel kommun (se nästa
stycke).</p>
<p>För närvarande finns endast stockholmskommunerna och några norrlandskommuner
med, eftersom det krävs manuellt arbete för att avgöra vilka postorter som hör
till vilken kommun. Om du vet vilka postorter som hör till en viss kommun, så
får du gärna kontakta mig (&#115;amuel <!--"
-->snabel-a kodafritt punkt se), så lägger jag in den. Vissa postorter kan dock
tillhöra flera kommuner, eller så kanske inte postortens gräns stämmer överrens
med kommungränsen. Kopplingarna från postort till kommun finns att ladda ner
<a href="https://github.com/samuellb/pnr96addrstats/blob/master/postort2kommun.csv">här</a> (endast stockholmskommunerna är
fullständiga som sagt. CC0-licens). I teorin vore det bättre att räkna per
postort och använda postnummerpolygonerna från
<a href="http://postnummeruppror.nu/">Postnummer­uppror</a> istället, men i
skrivande stund så verkar det fungera bättre med kommungränserna i OSM.</p>
<p>Källkoden till skripten som generade denna sida finns på <a href="https://github.com/samuellb/pnr96addrstats">GitHub</a>.</p>
<p><em>Kvar =</em> Saknas i OpenStreetMap, men finns i PNR96.<br>
<em>Okänd =</em> Finns i OpenStreetMap, men finns inte i PNR96. Kan t.ex. vara en ny väg, eller en felstavning.</p>
<table>
<thead>
<tr><th rowspan="2">SCB-nr</th><th rowspan="2">Kommun</th><th colspan="2">Vägar</th></tr>
<tr><th>Kvar %</th><th>Okända %</th></tr>
</thead>
<tbody>
EOF
while read objtype objid scbnummer kortnamn langnamn pnr_missing pnr_total pnr_unknown osm_total; do
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$scbnummer" "$objid" "$kortnamn" "$langnamn" "$pnr_missing" "$pnr_total" "$pnr_unknown" "$osm_total"
done < data/kommuner_data.csv | sort -n | while read scbnummer objid kortnamn langnamn pnr_missing pnr_total pnr_unknown osm_total; do
    # Kvar %
    if [ "$pnr_total" != 0 ]; then
        wr=$(($pnr_missing * 100 / $pnr_total))
    else
        wr="-"
    fi
    # Okända %
    if [ "$osm_total" != 0 ]; then
        wu=$(($pnr_unknown * 100 / $osm_total))
    else
        wu="-"
    fi
    wrs=""
    case "$wr" in
    0) wrs="rg";;
    1|2|3|4|5|6|7|8|9) wrs="r9";;
    1?) wrs="r8";;
    2?) wrs="r7";;
    3?) wrs="r6";;
    4?) wrs="r5";;
    5?) wrs="r4";;
    6?) wrs="r3";;
    7?) wrs="r2";;
    8?) wrs="r2";;
    9?|???*) wrs="r1";;
    esac
    wus=""
    case "$wu" in
    0) wus="rg";;
    1|2|3|4|5|6|7|8|9) wus="r9";;
    1?) wus="r8";;
    2?) wus="r7";;
    3?) wus="r6";;
    4?) wus="r5";;
    5?) wus="r4";;
    6?) wus="r3";;
    7?) wus="r2";;
    8?) wus="r2";;
    9?|???*) wus="r1";;
    esac
    echo "<tr><td>$scbnummer</td><td>$kortnamn</td><td class=\"$wrs\"><a href=\"data/${scbnummer}_missing_roads.html\">$wr%</a></td><td class=\"$wus\"><a href=\"data/${scbnummer}_unknown_roads.html\">$wu%</a></td></tr>"
done

footer_html

} > kommuner.html

