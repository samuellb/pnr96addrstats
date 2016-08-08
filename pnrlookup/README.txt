The pnrlookup PHP script allows for querying for information for a
particular street in a particular municipality.

The query format is:

    lookup.php?municipality=136&roadname=VALLAVÄGEN

This generates an information page with the following information:

  - Postal code (postnummer)
  - Name of postal town (postort)
  - List of streets in the given postal code.


To use the script, you must generate a SQLite database with the dbgen.py
script. As with the other scripts, you must have the pnr96 database in a
directory (or symbolic link) called "pnr96" directly under your
pnr96addrstats directory.


