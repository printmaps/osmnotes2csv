#!/usr/bin/perl

# -----------------------------------------
# Program : osmnotes2csv.pl
# Version : 0.1.0 - 2015/10/02 initial version
#           0.1.1 - 2015/10/03 help text modified
#
# Copyright (C) 2015 Klaus Tockloth
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program uses code snippets from https://github.com/richlv/osmnotes.
#
# Contact (eMail): <freizeitkarte@googlemail.com>
#
# Test:
# perl osmnotes2csv.pl -bbox=7.4713978,51.84335291,7.78056929,52.05879096 -csvfile=osmnotes.csv
# -----------------------------------------

use warnings;
use strict;
use English qw( -no_match_vars );
use 5.010;

use File::Basename;
use Getopt::Long;
use JSON;
use LWP::UserAgent;

# constants
my $EMPTY   = q{};
my $VERSION = '0.1.1';

my $program_name = basename ( $PROGRAM_NAME );
my $program_info = sprintf ( "%s, %s, OSM-Notes -> CSV-File", $program_name, $VERSION );

# command line parameters
my $help    = $EMPTY;
my $bbox    = $EMPTY;
my $csvfile = $EMPTY;
my $proxy   = $EMPTY;
my $timeout = $EMPTY;
my $limit   = $EMPTY;
my $closed  = $EMPTY;

GetOptions ( 'h|?'       => \$help,
             'bbox=s'    => \$bbox,
             'csvfile=s' => \$csvfile,
             'proxy=s'   => \$proxy,
             'timeout=i' => \$timeout,
             'limit=i'   => \$limit,
             'closed=i'  => \$closed );

if ( ( $help ) || ( $bbox eq $EMPTY ) || ( $csvfile eq $EMPTY ) ) {
    # print help
    printf {*STDERR} ( "\n" );
    printf {*STDERR} ( "%s\n", $program_info );
    printf {*STDERR} ( "\n" );
    printf {*STDERR} ( "Usage:\n" );
    printf {*STDERR} ( "perl $program_name -bbox=lon,lat,lon,lat -csvfile=name  <-proxy=url> <-limit=n> <-closed=n>\n" );
    printf {*STDERR} ( "\n" );
    printf {*STDERR} ( "Example:\n" );
    printf {*STDERR} ( "perl $program_name -bbox=7.4713978,51.84335291,7.78056929,52.05879096 -csvfile=osmnotes.csv\n" );
    printf {*STDERR} ( "\n" );
    printf {*STDERR} ( "Parameters:\n" );
    printf {*STDERR} ( "-bbox    = bounding box (left,bottom,right,top)\n" );
    printf {*STDERR} ( "-csvfile = name of resulting csv file\n" );
    printf {*STDERR} ( "\n" );
    printf {*STDERR} ( "Options:\n" );
    printf {*STDERR} ( "-proxy   = internet proxy server (default: none)\n" );
    printf {*STDERR} ( "           eg. http://proxy.apple.de:8080\n" );
    printf {*STDERR} ( "           eg. http://user42:password84\@proxy.apple.de:8080\n" );
    printf {*STDERR} ( "-timeout = response timeout in seconds (default: 53)\n" );
    printf {*STDERR} ( "-limit   = maximum number of notes (default: 999)\n" );
    printf {*STDERR} ( "-closed  = closed notes (0=none, -1=all, 1-n=days) (default: 0)\n" );
    printf {*STDERR} ( "\n" );
    exit ( 1 );
}

# create an internet user agent
my $ua = LWP::UserAgent->new;
my $agent = sprintf ( "%s/%s", $program_name, $VERSION );
$ua->agent ( $agent );

if ( $proxy ne $EMPTY ) {
    $ua->proxy ( 'http', $proxy );
}

if ( $timeout eq $EMPTY ) {
    $timeout = 53;
}
$ua->timeout ( $timeout );


if ( $limit eq $EMPTY ) {
    $limit = 999;
}

if ( $closed eq $EMPTY ) {
    $closed = 0;
}

printf {*STDERR} ( "\n" );
printf {*STDOUT} ( "%s\n", $program_info );
printf {*STDERR} ( "\n" );
printf {*STDOUT} ( "bbox    = %s\n", $bbox );
printf {*STDOUT} ( "csvfile = %s\n", $csvfile );
printf {*STDOUT} ( "proxy   = %s\n", $proxy );
printf {*STDOUT} ( "timeout = %s\n", $timeout );
printf {*STDOUT} ( "limit   = %s\n", $limit );
printf {*STDOUT} ( "closed  = %s\n", $closed );
printf {*STDERR} ( "\n" );

printf {*STDERR} ( "Requesting OSM notes ...\n" );
my $osm_base_uri = 'http://api.openstreetmap.org/api/0.6/notes.json';
my $osm_request_uri = sprintf ( "%s?bbox=%s&limit=%d&closed=%d", $osm_base_uri, $bbox, $limit, $closed );
printf {*STDOUT} ( "Request uri = %s\n", $osm_request_uri );
printf {*STDOUT} ( "User agent = %s\n",  $agent );

my $osm_response = $ua->get ( $osm_request_uri );
if ( !$osm_response->is_success ) {
    printf {*STDERR} ( "ERROR  : The OSM service request failed.\n" );
    printf {*STDERR} ( "STATUS : %s\n", $osm_response->status_line );
    exit ( 2 );
}

printf {*STDERR} ( "Processing JSON response ...\n" );
my $osm_content = $osm_response->decoded_content;
my $parsed_note_json = decode_json ( $osm_content );
if ( $parsed_note_json->{type} ne 'FeatureCollection' ) {
    printf {*STDERR} ( "ERROR: The incoming JSON data are not of type 'FeatureCollection'.\n" );
    exit ( 3 );
}

my $feature_ref   = $parsed_note_json->{features};
my $feature_count = @$feature_ref;

printf {*STDERR} ( "Writing OSM notes to utf8 CSV file ...\n" );
open ( my $OUTFILE, '>:encoding(UTF-8)', $csvfile ) or die ( "Error opening output file \"$csvfile\": $OS_ERROR\n" );

# print CSV header to file
printf {$OUTFILE} ( "\"%s\";\"%s\";\"%s\";\"%s\";\"%s\";\"%s\";\"%s\";\n", 'Note', 'Longitude', 'Latitude', 'Timestamp', 'User', 'Action', 'Text' );

foreach ( my $featureid = 0 ; $featureid < $feature_count ; $featureid++ ) {
    my $note = $parsed_note_json->{features}[$featureid];
    parse_osmnote ( $note );
}

close ( $OUTFILE ) or die ( "Error closing output file \"$csvfile\": $OS_ERROR\n" );

printf {*STDOUT} ( "%d OSM notes written.\n", $feature_count );
printf {*STDERR} ( "\n" );

exit ( 0 );


# -----------------------------------------
# Parse a single OSM note.
# -----------------------------------------
sub parse_osmnote {
    my ( $note ) = @_;

    my $note_id            = $note->{properties}->{id};
    my $lon                = $note->{geometry}->{coordinates}[0];
    my $lat                = $note->{geometry}->{coordinates}[1];
    my $date_created       = $note->{properties}->{date_created};
    my $note_comments      = $note->{properties}->{comments};
    my $note_comment_count = @$note_comments;

    foreach ( my $comment_id = 0 ; $comment_id < $note_comment_count ; $comment_id++ ) {
        my $comment_date   = $note->{properties}->{comments}[$comment_id]->{date};
        my $comment_user   = $note->{properties}->{comments}[$comment_id]->{user};
        my $comment_text   = $note->{properties}->{comments}[$comment_id]->{text};
        my $comment_action = $note->{properties}->{comments}[$comment_id]->{action};
        if ( !$comment_user ) {
            $comment_user = 'anonym';
        }
        # printf {*STDOUT} ( "note_id        = %s\n", $note_id );
        # printf {*STDOUT} ( "lon            = %s\n", $lon );
        # printf {*STDOUT} ( "lat            = %s\n", $lat );
        # printf {*STDOUT} ( "date_created   = %s\n", $date_created );
        # printf {*STDOUT} ( "comment_date   = %s\n", $comment_date);
        # printf {*STDOUT} ( "comment_user   = %s\n", $comment_user);
        # printf {*STDOUT} ( "comment_action = %s\n", $comment_action);
        # printf {*STDOUT} ( "comment_text   = %s\n", $comment_text);
        # printf {*STDOUT} ( "\n");

        # print CSV data to file
        $comment_text =~ tr/"/'/;
        $comment_text =~ tr/\n/ /;
        printf {$OUTFILE}
            ( "\"%s\";\"%s\";\"%s\";\"%s\";\"%s\";\"%s\";\"%s\";\n", $note_id, $lon, $lat, $comment_date, $comment_user, $comment_action, $comment_text );
    }

    return;
}
