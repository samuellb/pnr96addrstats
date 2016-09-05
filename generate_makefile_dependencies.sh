#!/bin/bash

mkdir -p data
[ ! -e data/kommuner.csv ] && ./get_kommuner.sh

stockholm_deps=$(awk '{ print $3 }' < data/kommuner.csv | grep ^01 | while IFS= read -r objid; do
    echo "data/roads_${objid}.csv"
done | tr '\n' ' ')

cat <<EOF > deps.mk
.PHONY: stockholm
stockholm: ${stockholm_deps}
EOF
