## OSM-Notes -> CSV-File

**Description**  
osmnotes2csv.pl is a command line utility written in Perl.
It can be used on all operating systems where a Perl interpreter is available (eg. Linux, OSX, Windows).
It's purpose is to retrieve all OSM notes placed within a defined area described by a bounding box.
The tool uses the OSM API (0.6) for requesting the data.
The responding data is transformed and stored into an utf8-encoded CSV file.
This file can be imported into a spreadsheet application for further processing.
This program also works if you are behind an internet proxy server (see options).

**Usage**  
```
Usage:
perl osmnotes2csv.pl -bbox=lon,lat,lon,lat -csvfile=name  <-proxy=url> <-limit=n> <-closed=n>

Example:
perl osmnotes2csv.pl -bbox=7.4713978,51.84335291,7.78056929,52.05879096 -csvfile=osmnotes.csv

Parameters:
-bbox    = bounding box (left,bottom,right,top)
-csvfile = name of resulting csv file

Options:
-proxy   = internet proxy server (default: none)
           eg. http://proxy.apple.de:8080
           eg. http://user42:password84@proxy.apple.de:8080
-timeout = response timeout in seconds (default: 53)
-limit   = maximum number of notes (default: 999)
-closed  = closed notes (0=none, -1=all, 1-n=days) (default: 0)
```

**History**  
Release 0.1.1 (2015/10/03):  
Small improvements.  

Release 0.1.0 (2015/10/02):  
Initial version.  

