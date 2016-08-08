#!/usr/bin/env python
# encoding: utf-8
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

import sqlite3, json, csv

pnr96path = '../pnr96/pnr96-streets.json'
municipalities_path = '../data/kommuner.csv'
p2k_path = '../postort2kommun.csv'


db = sqlite3.connect('pnr96.sqlite')
db.text_factory = str
c = db.cursor()

c.execute('''CREATE TABLE pnr96 (
streetName VARCHAR(255) NOT NULL,
postalCode INTEGER NOT NULL,
postalTown VARCHAR(50) NOT NULL
)''')

c.execute('''CREATE TABLE kommun (
municipalityScb INTEGER NOT NULL PRIMARY KEY,
municipalityName VARCHAR(50) NOT NULL
)''')

c.execute('''CREATE TABLE postort2kommun (
postalTown VARCHAR(50) NOT NULL PRIMARY KEY,
municipalityScb INTEGER NOT NULL
)''')

# Insert PNR96 data
pnrdata = json.load(open(pnr96path))
for row in pnrdata:
    c.execute('INSERT INTO pnr96 VALUES (?, ?, ?)',
              [row['streetName'], row['postalCode'], row['postalTown']])

# Insert municipality data
kcsv = csv.reader(open(municipalities_path), delimiter='\t')
next(kcsv) # skip header row
for row in kcsv:
    scbnumber = int(row[2])
    name = unicode(row[3], "utf-8").upper()
    c.execute('INSERT INTO kommun VALUES (?, ?)', [scbnumber, name])
    # Check if there's a postal town for this municipality
    c.execute('SELECT postalTown FROM pnr96 WHERE postalTown = ? LIMIT 1', [name])
    rows = c.fetchall()
    if len(rows) == 1:
        c.execute('INSERT INTO postort2kommun VALUES (?, ?)', [name, scbnumber])

# Insert postal town -> municipality mappings
kcsv = csv.reader(open(p2k_path), delimiter='\t')
next(kcsv)
for row in kcsv:
    if len(row) < 2:
        continue # mapping has not yet been defined for this postal town
    postalTown = row[0]
    municipalityName = row[1]
    c.execute('SELECT municipalityScb FROM kommun WHERE municipalityName = ? LIMIT 1', [municipalityName])
    rows = c.fetchall()
    if len(rows) == 0:
        raise Exception("Municipality not found: %s" % municipalityName)
    municipalityScb = int(rows[0][0])
    c.execute('INSERT INTO postort2kommun VALUES (?, ?)', [postalTown, municipalityScb])

# Create indices
c.execute('CREATE INDEX pnr96_streetName ON pnr96 (streetName)')

c.close()
db.close()


