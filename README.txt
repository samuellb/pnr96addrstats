These scripts can be used to generate lists of missing or unknown road names
in Sweden. Currently, only the Greater Stockholm area and some areas in
Norrland are handled.

You can see it in action here:

    http://samuellb.users.openstreetmap.se/pnr96addrstats/jekyll/


If you want to run it on your own server, you need to:

1. Download the PNR-96 database. Put the files in a directory called "pnr96"
   in the addrstats directory. The database can be downloaded here:

   http://kalle.users.openstreetmap.se/pnr96/

2. If you need additional municipalities, add mappings from postal town to
   municipality name in postort2kommun.csv. Then adjust the
   addrstats_update.sh script to process these municipalities.

3. Build the site. This will download whats required automatically.

    make jekyll

4. Optionally, set up a cron job to run the above e.g. weekly or monthly.


All data is ODbL licensed, except for the PNR-96 database which is
out-of-copyright, and the postort2kommun.csv file which is CC0 licensed.
The source code is MIT licensed (see the headers of each file for details).


A word of caution if you plan to use the postort2kommun.csv file: This file
is not only missing a lot of data currently, there are also places where the
municipality and postal town borders differ. You may want to have a look at
http://postnummeruppror.nu/ instead, depending on what you want to do. Also,
that site has current postal towns, unlike the postort2kommun.csv file, which
has postal town names from 1996.

