#!/bin/bash

. env.sh

overpass kommuner.csv '/interpreter?data=[out:csv(::"type",::"id","ref:scb",short_name,name)];rel["admin_level"="7"]["ref:scb"];out tags qt;&bbox='"${swedenbbox:?}"
