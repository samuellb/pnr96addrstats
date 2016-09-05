$(shell ./generate_makefile_dependencies.sh)
include deps.mk

data/roads_%.csv: data/kommuner.csv
	./get_data.sh $*

data/kommuner.csv:
	./get_kommuner.sh

.PHONY: jekyll
jekyll: data/pnr96_kommun.csv stockholm data/roads_2482.csv data/roads_2518.csv data/roads_2521.csv data/roads_2513.csv data/roads_2584.csv
	mkdir -p jekyll/_unknown_roads jekyll/_missing_roads
	./jekyll_roads_data.sh
	cd jekyll && jekyll build

data/pnr96_kommun.csv: pnr96/pnr96-streets.json
	./pnr_index.sh

jekyll/_data/kommuner_overview.csv:
	mkdir -p jekyll/_data/
	./kommuner_overview.sh
