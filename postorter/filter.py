#!/usr/bin/env python2
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

import sqlite3, re

# This script is used to fill in missing post towns <-> municipality mappings
# in postort2kommun.csv. It generates a osm file with known post towns and
# known places. With this osm file + the municipality borders osm file
# (graenser.osm.xml) you can easilly figure out which post town belongs to
# which municipality, although it will take some time.

# You need the "platser.osm.xml" file from http://kodapan.se/geodata/
# You also need to have generated the file "../pnrlookup/pnr96.sqlite"

db = sqlite3.connect('../pnrlookup/pnr96.sqlite')
db.text_factory = str
c = db.cursor()

# Very stupid XML parsing, but also very simple
nodestart = re.compile("\\s+<node[^>]*>")
nodeend = re.compile("\\s+</node>")
nametag = re.compile("\\s+<tag k='name' v='([^']*)' />")
nametagreplace = re.compile("(\\s+<tag k='name' v=')([^']*)(' />)")

pf = open("platser.osm.xml")
outf = open("postorter.osm.xml", "w")
in_node = False
accept = False
node_data = ''

outf.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<osm version=\"0.6\" upload=\"false\" generator=\"pnr96addrstats-postorter\">\n")
for line in pf:
    if not in_node and nodestart.match(line):
        in_node = True
        accept = False
        node_data = line
    elif in_node:
        if nodeend.match(line):
            node_data += line
            in_node = False
            if accept:
                outf.write(node_data)
        elif nametag.match(line):
            # A name=... tag
            m = nametag.match(line)
            value = unicode(m.groups()[0], 'utf-8').upper()
            print "name=<%s>" % value
            # Check if it exists in the postort database
            c.execute('SELECT postalCode FROM pnr96 WHERE postalTown = ? LIMIT 1', [value])
            rows = c.fetchall()
            if len(rows) == 1:
                print "MATCH!"
                accept = True
                postcode = rows[0][0]
                line = nametagreplace.sub('\\1\\2['+str(postcode)+']\\3', line, 1)
            node_data += line
        else:
            node_data += line
            
            
outf.write("</osm>\n")

c.close()
db.close()


