#!/usr/bin/perl

use strict;

my $successful_downloads = `wc -l download_corpus_DOWNLOADED.log`;
my $unavailable          = `wc -l download_corpus_DOWNLOAD_UNAVAILABLE.log`;
my $empty                = `wc -l download_corpus_EMPTYFILE.log`;

# remove filenames from wc -l results
$successful_downloads =~ s/download_corpus.*log//g;
$unavailable  =~ s/download_corpus.*log//g;
$empty  =~ s/download_corpus.*log//g;

#print out output.
print "\n";
print "SUMMARY OF DOCUMENTS DOWNLOADED\n";
print "-------------------------------\n";
print "Number of successful downloads:  $successful_downloads";
print "Number of unavailable documents: $unavailable";
print "Number of empty documents:       $empty\n";
