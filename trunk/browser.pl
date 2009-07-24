#!/usr/bin/perl

=head1 NAME

browser.pl - BioCaster Event Browser (Mike Conway, NII, Tokyo. 19th May 2009)

=head1 DESCRIPTION

Due to copyright restrictions, we are unable to distribute the source text files for the 200 document Biocaster Event Corpus.  Instead, we have provided a download script and a browser to inspect the documents and their associated events.

We have stripped the html from the documents and colour coded locations (green) and diseases (red).

Note that the script must be run in its appropriate directory in order to find the event data files.


=cut


# DEBUGGING (UNCOMMENT IF EDITING)
# use strict;
# use warnings;
# use diagnostics;

# SEND STDERR > /dev/null
open(STDERR, ">/dev/null");

use LWP::Simple;
use HTML::Strip;
use Encode;

use Tk;
use Tk::MsgBox;
use Tk::LabFrame;
use Tk::ROText;

##################################################
# DATA
##################################################
# Data is loaded from files in the ./data subdirectory
# using the subroutine "load_data()"
our @urls;  
our @file_names;# This var is used to fill the list box
our @notes;
our @promed_numbers;
our @DISEASES;
our @LOCATIONS;
load_data();  # subroutine that loads data

our $current_url = "";

##################################################
# VERSION CONTROL VARIABLES
##################################################
# Version Control Information
our $VERSION = (qw$Revision: 1.12 $)[-1];
our $DATE    = (qw$Date: 2009/05/20 13:23:47 $)[-2];
our $AUTHOR  = "Mike Conway";


##################################################
# MAIN WINDOW GUI
##################################################
my $mw = MainWindow->new;
$mw->title("BioCaster Event Corpus Browser");
$mw->resizable(0,0);

# Add a simple menu bar
$mw->configure( -menu => my $menubar = $mw->Menu);
my $file = $menubar->cascade(
    -label   => 'File',
    -tearoff => 0,
    );

my $help = $menubar->cascade(
    -label   => 'Help',
    -tearoff => 0,
);


my $menubutton_exit = $file->command(
    -label   => 'Exit',
    -command => 'exit',
);

my $menubutton_about = $help->command(
    -label   => 'About',
    -command => sub { about_messagebox() },
);

# STATUS BAR
my $message = "";
$mw->Label(
    -textvariable => \$message,
    -borderwidth  => 2,
    -relief       => 'groove',
    -justify      => 'left',
  )->pack(
    -fill => 'x',
    -side => 'bottom'
  );



my $lf_holderforfilelist = $mw->LabFrame(
    -label     => "File List",
    -labelside => 'acrosstop'
)->pack( -side => 'top', );

my $list = $lf_holderforfilelist->Scrolled(
    'Listbox',
    -scrollbars    => 'osoe',
    -height        => 3,
    -width         => 112,
    -selectmode    => "browse",
    -takefocus     => 0,
    -selectmode    => "single",
)-> pack();
$list-> bind('<Button-1>', sub { list_box_selection() } );
# put file names into list box
$list-> insert (0, @file_names);


my $lf_holderfortextbox = $mw->LabFrame(
    -label     => "File Viewer",
    -labelside => 'acrosstop'
)->pack( -side => 'left', );


my $text = $lf_holderfortextbox->Scrolled(
    'ROText',
    -width           => 100,
    -height          => 40,
    -borderwidth     => 3,
    -exportselection => 1,
    -takefocus       => 0,
    -wrap            => 'none',
    -background      => "white",
    -scrollbars      => "osoe",
    -exportselection => 1,
)->pack();

my $lf_holderforeventbox = $mw->LabFrame(
    -label     => "Event Viewer",
    -labelside => 'acrosstop'
)->pack( -side => 'right', );


my $event_text = $lf_holderforeventbox->Scrolled(
    'ROText',
    -width           => 45,
    -height          => 40,
    -borderwidth     => 3,
    -exportselection => 1,
    -takefocus       => 0,
    -wrap            => 'none',
    -background      => "white",
    -scrollbars      => "osoe",
    -exportselection => 1,
)->pack();

# text colour tags
$text->tagConfigure("red", -background => "red");
$text->tagConfigure("green", -background => "green");

$event_text->tagConfigure("red", -background => "red");
$event_text->tagConfigure("green", -background => "green");

MainLoop;


###################################################
# GENERAL SUBROUTINES
####################################################
sub load_data {
    # Open 2 data files in ./data subdirectory
    open(FILE_1, "<./urls/original_100_kappa_tested.txt") ||
        die("Cannot open file 1 for reading: $.\n");
    open(FILE_2, "<./urls/additional_100.txt") ||
        die("Cannot open file 2 for reading: $.\n");

    # Load file data into an array
    my @data;
    while(<FILE_1>) {
        chomp $_;
        push (@data, $_);
    }
    while(<FILE_2>) {
        chomp $_;
        push (@data, $_);
    }

    # populate @file_names, @availables, @notes, and @promed_numbers
    # and @file_names global variables from data array
    for (my $i = 0; $i < scalar(@data); $i++) {
        my $line = $data[$i];
        my @fields = split(/\s+/, $line);
        my $file = $fields[0];
        push(@file_names, $file);

        my $url = $fields[1];
        push(@urls, $url);
    }
}

# Main program control subroutine
sub list_box_selection {
    my @selected = $list->curselection;
    undef @DISEASES;
    undef @LOCATIONS;
    my $selected = $selected[0];
    my $url = $urls[$selected]; # puts url in status bar
    my $filename = $file_names[$selected];
    my $raw_text = "";
    unless ($url =~ /\[NOT/) {
        $message = "Downloading...";
        $mw->update;
        $raw_text = get($url);
        $message = $url;
    }
    if ($url =~ /\[NOT/) { $message = "NOT AVAILABLE"; }
    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse($raw_text);
    # deal with encoding issue
    $clean_text = decode('utf8', $clean_text);
    $clean_text =~ s/[^!-~]/ /g;
   
    my $event_filename = $filename . ".event";
    # this puts the events into the event text box
    open (EVENT, "<./events/$event_filename") ||
        die ("Cannot open Event file $event_filename.  $!\n");

    my $event_string;
    while (<EVENT>) {
        $event_string = $event_string . $_;
    }
    # decode to avoid strange formatting
    $event_string = decode('utf8', $event_string);
    $event_string =~ s/[^!-~]/ /g;
    $event_text->delete("1.0", "end");
    $event_string = format_event($event_string);
   
    
    my @words = split(/\s+/, $clean_text);

    
    @DISEASES = unique(@DISEASES);
    @LOCATIONS = unique(@LOCATIONS);
    $text->delete("1.0", "end");
    my $wrap_counter = 0;
    my $wrap_size = 10;

    # This loop colourizes text up to 3 words long.
  LOOP:   for(my $i = 0; $i < scalar(@words); $i++) {
        my $word = $words[$i];
        my $two_words = $word . " " . $words[$i+1];
        my $three_words = $word . " " . $words[$i+1] . " " . $words[$i+2];
                                                                     
        $wrap_counter++;
        if ($wrap_counter % 10 == 0) {
            $text->insert('end', "\n");
        }
        
        # Find number of characters in word, if word is too long, then
        # skip and move to next word
        my @characters = split(//,$word);
        my $number_chars = scalar(@characters);
        if ($number_chars > 15) { next; }

        my $flag = 0;
        
        foreach my $disease (@DISEASES) {
            if ($three_words eq  $disease) {
                $text->insert('end', "$three_words", "red");
                $text->insert('end', " ");
                $i = $i + 2;
                next LOOP;
            }

            if ($two_words eq  $disease) {
                $text->insert('end', "$two_words", "red");
                $text->insert('end', " ");
                $i = $i +1;
                next LOOP;
            }

            if ($word =~ /$disease/) {
                $text->insert('end', "$word", "red");
                $text->insert('end', " ");
                $flag = 1;
                next LOOP;
            }
        }
        
        foreach my $location (@LOCATIONS) {
            if ($three_words eq  $location) {
                $text->insert('end', "$three_words", "green");
                $text->insert('end', " ");
                $i = $i +2;
                next LOOP;
            }
            if ($two_words eq  $location) {
                $text->insert('end', "$two_words", "green");
                $text->insert('end', " ");
                $i = $i + 1;
                next LOOP;
            }
             
            if ($word =~ /$location/) {
                $text->insert('end', "$word", "green");
                $text->insert('end', " ");
                $flag = 1;
                next LOOP;
            }     
        }
        if ($flag == 0) {
            $text->insert('end', "$word "); $text->insert('end', " ");
        }
    }
    
    $mw->update;
    
} # end sub list_box_selection


#This colourizes the Event Frame Panel
sub format_event {
    my $string = $_[0];
    my $event_counter = 1;
    # First, identify each event
    my @events = $string =~ /<EVENT .*?<\/EVENT>/gs;
    
    foreach my $event (@events) {
        $event_text->insert('end', "EVENT $event_counter\n");
        #DISEASE
      
        if ($event =~ /name="HAS_DISEASE" type="DISEASE" content="(.*?)" alt="(.*?)"/g) {
            my @temp;
            $temp[0] = $1;
            $temp[1] = $2;
            my @disease = pipe_parse(@temp);
            push(@DISEASES, @disease);
            my $disease_string = "|";
            foreach my $t (@disease) {
                $disease_string = $disease_string . "$t|";
            }
            $disease_string =~ s/\|\|/|/gs;
            my $temp_string =  "   " . "DISEASE:        " . $disease_string . "\n";
            $event_text->insert('end',  $temp_string, "red");
        }


        #HAS_AGENT
        if ($event =~ /name="HAS_AGENT" type="micro_organism" content="(.*?)" alt="(.*?)"/g) {
            my @temp;
            $temp[0] = $1;
            $temp[1] = $2;
            my @accu = pipe_parse(@temp);
            push(@DISEASES,@accu);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;    
            my $temp_string =  "   " . "AGENT:          " . $string . "\n";
            $event_text->insert('end',  $temp_string, "red");
        }

     
            
        if ($event =~ /COUNTRY.*?LOCATION.*?content="(.*?)".*?alt="(.*?)"/ ) {
            my @temp;
            $temp[0] = $1;
            $temp[1] = $2;
            my @accu = pipe_parse(@temp);
            push(@LOCATIONS, @accu);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;    
            my $temp_string =  "   " . "COUNTRY:        " . $string . "\n";
            $event_text->insert('end',  $temp_string, "green");
        }

        if ($event =~ /PROVINCE.*?LOCATION.*?content="(.*?)".*?alt="(.*?)"/ ) {
            my @temp;
            $temp[0] = $1;
            $temp[1] = $2;
            my @accu = pipe_parse(@temp);
            push(@LOCATIONS, @accu);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;    
            my $temp_string =  "   " . "PROVINCE:       " . $string . "\n";
            $event_text->insert('end',  $temp_string, "green");
        }

        if ($event =~ /OTHER.*?LOCATION.*?content="(.*?)".*?alt="(.*?)"/ ) {
            my @temp;
            $temp[0] = $1;
            $temp[1] = $2;
            my @accu = pipe_parse(@temp);
            push(@LOCATIONS, @accu);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;    
            my $temp_string =  "   " . "LOCATION_OTHER: " . $string . "\n";
            $event_text->insert('end',  $temp_string, "green");
        }

        
        #HAS_SPECIES
        if ($event =~ /name="HAS_SPECIES" type="animal" content="(.*?)" alt="(.*?)"/g) {
            my @temp;
            $temp[0] = $1;
            $temp[1] = $2;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;    
            my $temp_string =  "   " . "SPECIES:        " . $string . "\n";
            
            $event_text->insert('end',  $temp_string);
        }

        #TIME.RELATIVE
        if ($event =~ /name="TIME.relative" type="string" content="(.*?)"/g) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my $temp_string =  "   " . "TIME:           " . $string . "\n";
            $event_text->insert('end',  $temp_string);
        }

        # INTERNATIONAL TRAVEL
        if ($event =~ /name="INTERNATIONAL_TRAVEL" type="Boolean" content="(.*?)"/gi) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my $temp_string = "   " . "INTERNATIONAL:  " . $string . "\n";
            $event_text->insert('end',  $temp_string);
        }

        #DELIBERATE RELEASE
        if ($event =~ /name="DELIBERATE_RELEASE" type="Boolean" content="(.*?)"/gi) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my $temp_string = "   " . "DELIBERATE:     " . $string . "\n";
            $event_text->insert('end',  $temp_string);
        }
        #ZOONOSIS
        if ($event =~ /name="ZOONOSIS" type="Boolean" content="(.*?)"/gi) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my $temp_string = "   " . "ZOONOSIS:       " . $string . "\n";
            $event_text->insert('end',  $temp_string);
        }

        #DRUG RESISTANCE
        if ($event =~ /name="DRUG_RESISTANCE" type="Boolean" content="(.*?)"/gi) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my $temp_string =  "   " . "DRUG_RESISTANCE:" . $string . "\n";
            $event_text->insert('end',  $temp_string);
        }

        #FOOD CONTAM
        if ($event =~ /name="FOOD_CONTAMINATION" type="Boolean" content="(.*?)"/gi) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my $temp_string = "   " . "FOOD_CONTAM:    " . $string . "\n";
            $event_text->insert('end',  $temp_string);
        }
        
        # HOSPITAL WORKER
        if ($event =~ /name="HOSPITAL_WORKER" type="Boolean" content="(.*?)"/gi) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my $temp_string = "   " . "HOSP_WORKER:    " . $string . "\n";
            $event_text->insert('end',  $temp_string);
        }

        # FARM WORKER
        if ($event =~ /name="FARM_WORKER" type="Boolean" content="(.*?)"/gi) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my $temp_string =  "   " . "FARM_WORKER:    " . $string . "\n";
            $event_text->insert('end',  $temp_string);
        }

        # PRODUCT MALFORMATION
        if ($event =~ /name="PRODUCT_MALFORMATION" type="Boolean" content="(.*?)"/gi) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my  $temp_string = "   " . "MALFORMED:      " . $string . "\n";
            $event_text->insert('end',  $temp_string);
        }

        # NEW TYPE AGENT
        if ($event =~ /name="NEW_TYPE_AGENT" type="Boolean" content="(.*?)"/gi) {
            my @temp;
            $temp[0] = $1;
            my @accu = pipe_parse(@temp);
            my $string = "|";
            foreach my $t (@accu) {
                $string = $string . "$t|";
            }
            $string =~ s/\|\|/|/gs;
            my $temp_string =  "   " . "NEW_AGENT:      " . $string . "\n";
            $event_text->insert('end',  "$temp_string\n");
        }
  
        $event_counter++;
    }                           # end main foreach loop     
}   # end sub format_event 



# Accepts a list of the form (disease, disease|disease|disease, disease)
# and returns (disease, disease, disease, disease, disease).
sub pipe_parse {
    my @input = @_;
    my @output;
    foreach my $element (@input) {
        if ($element !~ /\|/) {
            push(@output, $element);
        } else {
            my @split_on_pipe = split(/\|/, $element);
            push(@output, @split_on_pipe);
        }
    }
    return @output;
}

sub unique {
    my @list = @_;
    my %seen = ();
    my @uniq = ();
    foreach my $item (@list) {
        unless ($seen{$item}) {
            # if we get here, we have not seen it before
            $seen{$item} = 1;
            push(@uniq, $item) unless $item eq " ";
        }
    }
    return @uniq;
}

###################################################
# GUI SUBROUTINES
####################################################
sub about_messagebox {
    my $about_messagebox = $mw->MsgBox(
        -title   => 'About...',
        -message => "RCS: $VERSION\n\nDate: $DATE\n\nDeveloped by $AUTHOR\n",
        -type    => "ok",
    );
    $about_messagebox->resizable( 0, 0 );
    my $button = $about_messagebox->Show;
    return;
}

