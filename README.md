# README #

Prints the dependency graph that is specified in a CocoaPods.
Tested with CocoaPods v0.33.1. 

Takes a cocoapods pod file converts to dot file and then produces a directed graph 
visualisation using GraphViz tool "fdp".

The Postscript file produced can be opened in "Preview" on a mac.
The Dot filename is used as the name of the Postscript file.
