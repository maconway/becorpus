#!/usr/bin/perl 

# EVENT.PL April 2009
# This script extracts the event frames from annotated xml files and
# dumps them in a directory. Eg.
#     perl event.pl <DIRECTORY WHERE FILES LIVE>
# Note that all files are extracted recursively


use File::Find;
use Perl6::Slurp;
use File::Basename;
use strict;

# This is the directory where the complete files are stored:
my $dir = "/Users/mikeconway/data/becorpus/becorpus_200docs/";
my $current_dir = `pwd`;
chomp $current_dir;

find(\&wanted, $dir); 

sub wanted {
    # if file matches xml then extract the events and write to a file
    #in the events directory of the same file name + event
    my $full_path = $_;
    my $basename = basename($_);
    if (($basename =~ /\.xml/) && ($basename !~ /v/)) {
        my $text = slurp($full_path);
        my @events = $text =~ /<EVENT.*?>.*?<\/EVENT>/gs;
        print $events[0];
        open (EVENT_FILE, ">$current_dir/events/$basename.event") ||
            die ("Cannoto open $basename.event for writing: $!\n");
        foreach my $event (@events) {
            print EVENT_FILE $event . "\n";
        }
        close(EVENT_FILE);      
    }
}



