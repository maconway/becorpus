#!/usr/bin/perl

# MERGE_EVENTS.PL April 09 M.Conway
# This script works in conjunction with download_corpus.pl to construct
# a working version of the biocaster event corpus.  It merges the downloaded
# documents with the event frames.  Note that the event frames are provided
# in the original zip file (the "events" subdirectory). 

use strict;
use File::Basename;
use Perl6::Slurp;

# get filenames (including paths)
my @events = <./events/*.event>;
my @docs = <./clean_html/*.xml>;

# create directory for the new merged files to live in
mkdir "merged_files";


# As there are more document event frames than documents (i.e. some
# documents are not available for download) we have to check (and match)
# document to corresponding event frame.  This loop does that.
foreach my $doc (@docs) {
    my $doc_basename = basename($doc);
    foreach my $event (@events) {
        my $event_name = basename($event);
        # strip ".event" suffix for matching
        $event_name =~ s/\.event//g;

        if ($doc_basename eq $event_name) {
            my $doc_text = slurp($doc);
            my $event_text = slurp($event);

            # concatinate downloaded document and corresponding
            # event frame
            my $both = $doc_text . "\n" . $event_text;

            # This is the output file name
            # eg "193.xml.merged"
            my $output_file = $doc_basename . ".merged";

            # open filehandle for subdirectory
            open(OUTPUT, ">./merged_files/$output_file") ||
                die("Cannot open file $output_file for writing:  $!\n");
            print OUTPUT $both;
            close OUTPUT;
        } #end if        
    }#end event foreach
}#end doc foreach
