$(shell ./generate_makefile_dependencies.sh)
include deps.mk

data/roads_%.csv: data/kommuner.csv
	./get_data.sh $*

data/kommuner.csv:
	./get_kommuner.sh

kommuner.html: stockholm data/roads_2482.csv data/roads_2518.csv data/roads_2521.csv data/roads_2513.csv data/roads_2584.csv
	./addrstats_update.sh

.PHONY: jekyll
jekyll: stockholm data/roads_2482.csv data/roads_2518.csv data/roads_2521.csv data/roads_2513.csv data/roads_2584.csv
	./kommuner_overview.sh
	mkdir -p jekyll/_unknown_roads jekyll/_missing_roads
	./jekyll_roads_data.sh
	cd jekyll && jekyll build
