#!/usr/bin/perl 

# DOWNLOAD_CORPUS.PL  21st April 2009
# Perl Script for downloading biocaster Event Corpus from Internet


use strict;
use LWP::Simple;
use File::Basename;
use HTML::Strip;


# SEND STDERR > /dev/null
open(STDERR, ">/dev/null");


#Open each text file in the "urls" subdirectory and create an
#array for each line.
my @url_files = <./urls/*.txt>;

# Make output directories for files
mkdir("raw_html");
mkdir("clean_html");


my @lines;
foreach my $file (@url_files) {
    open(FILE, $file) ||
        die("Cannot open file $file for reading:  $!\n");
    while (<FILE>) {
        if ($_ =~ /^ *$/) {next;} # deals with blank lines
        chomp($_);
        push(@lines,$_);
    }
    close(FILE);
}

# @lines now contains all lines from the input text files.  Now these
# need to be parsed
my $total_number_of_files = scalar(@lines); my $counter = 1;
my @files_processed; #counter for actual num of files processed
my @url_processed; #counter for num of urls processed
my @files_unavailable;
my @url_unavailable;
my @files_empty;
my @url_empty;
foreach my $line (@lines) {
    # EXTRACT FILENAME
    my $filename;
    my @tempname = split(/ /, $line);  $filename = $tempname[0];

    # EXTRACT URL
    my $url;
    my @tempurl = split(/ /, $line); $url = $tempurl[1];
    # if line contains [NOT AVAILABLE] then skip
    if ($line =~ /NOT AVAILABLE/) {
        push (@files_unavailable, $filename);
        push (@url_unavailable, $url);
        next
    };


    # PRINT PROGRESS REPORT IN SHELL
    print "File number: $counter \n";
    print "Filename: $filename\n";
    print "URL: $url\n\n";
    $counter++;
    
    # PRINT RAW HTML TO FILE
    my $raw_text = get($url);
    # check for empty files
    if ($raw_text eq "") {
        push(@files_empty, $filename);
        push(@url_empty, $url);
        next;
    }



    open(RAW_OUTPUT, ">./raw_html/$filename") ||
        die ("Cannot write text to $filename:  $!\n");
    print RAW_OUTPUT $raw_text;
    close RAW_OUTPUT;

    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse($raw_text);

    
    
    # Remove all lines that are 3 words long or less
    my @ln = split(/\n/, $clean_text);
    my $string;
    foreach my $l (@ln) {
        my @number = split(/ +/, $l);
        if (scalar(@number) < 4) {next;}
        $string = $string . "$l\n";   
    }
    $clean_text = $string;
    
    open(CLEAN_OUTPUT, ">./clean_html/$filename") ||
        die("Cannot write text to $filename: $!\n");
    print CLEAN_OUTPUT $clean_text;
    close CLEAN_OUTPUT;
    
    # add processed filename and url to accumulater
    push(@files_processed, $filename);
    push(@url_processed, $url);
    sleep(2); # sleep for 2 seconds
}


# LOGGING

open(LOG_UNAVAILABLE, ">download_corpus_DOWNLOAD_UNAVAILABLE.log") ||
    die ("Cannot open file download_corpus.log for writing to log file: $!\n");
for (my $i = 0; $i < scalar(@files_unavailable); $i++) {
    print LOG_UNAVAILABLE "$files_unavailable[$i]" . "\t" . "$url_unavailable[$i]" . "\n";
}
close LOG_UNAVAILABLE;


open (LOG_DOWNLOADED, ">download_corpus_DOWNLOADED.log") ||
    die ("Cannot open file download_corpus_DOWNLOADED.log: $!\n");
for (my $i = 0; $i < scalar(@files_processed); $i++) {
    print LOG_DOWNLOADED "$files_processed[$i]" . "\t" . "$url_processed[$i]" . "\n";
}

close LOG_DOWNLOADED;

open (LOG_EMPTY, ">download_corpus_EMPTYFILE.log") ||
    die("Cannot open file download_corpus_EMPTYFILE.log");
for (my $i = 0; $i < scalar(@files_empty); $i++) {
    print LOG_EMPTY "$files_empty[$i]" . "\t" . "$url_empty[$i]" . "\n";
}

close LOG_EMPTY;

# Converts the files to ascii (there are many different input formats)
mkdir "./raw_html/ascii";

my @raw_files = <./raw_html/*.xml>;
foreach my $raw_file (@raw_files) {
    my $basename = basename($raw_file);
    system("iconv -c -t ASCII ./raw_html/$basename > ./raw_html/ascii/$basename");
}

mkdir "./clean_html/ascii";

my @clean_files = <./clean_html/*xml>;
foreach my $clean_file (@clean_files) {
    my $basename = basename($clean_file);
    system("iconv -c -t ASCII ./clean_html/$basename > ./clean_html/ascii/$basename");
}
