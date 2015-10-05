#!/bin/bash
#
# Takes a cocoapods pod file converts to dot file and then produces a directed graph visualisation using "fdp".
# The Postscript file produced can be opened in "Preview" on a mac.
#
# The Dot filename is used as the name of the Postscript file.
#
filename=`basename $1`
fileext=${filename##*.}
filename=`basename $filename .${fileext}`
echo "Converting $1 to ${filename}.ps"

# Convert the Podfile.lock to .dot
ruby ~/bin/pod2dot.rb $1 > $1.dot

# Convert the dot file to ps
# Preview can open ps file
fdp -Tps $1.dot -o ${filename}.ps
