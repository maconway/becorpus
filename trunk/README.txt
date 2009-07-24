README.txt April 2009 M.Conway
------------------------------

--- Introduction -------------

As source documents cannot be redistributed for copyright reasons, we
have provided a perl script that downloads as many documents as
possible, and then merges each downloaded document with its associated
event frame.  Note that event frames for all files are provided in the
"./events" subdirectory.  The event corpus consists of 200 documents.


--- Modules Required ---------

The downloading script requires a number of modules that may or may not be installed on your system.  The modules are:

    LWP::Simple
    Encode
    File::Find
    File::Basename
    Perl6::Slurp

(If necessary, modules can be installed using the command:

    sudo cpan MODULE_NAME
)

Note that the script is unlikely to work with Windows (it has been tested with Mac OS and Linux).


--- Downloading the Corpus ---

First, run the script in the "event_corpus" directory (i.e. the top
level directory of the zip file).  Then,

      perl download_corpus.pl

This takes a couple of minutes to run, it should provide a progress
report.  If the script will not run, check that all the necessary
modules are installed.

Next, to find out how successful the "download_corpus.pl" command was,
use:

        perl summary.pl

This gives a list of the number of documents successfully downloaded,
how may could not be downloaded, and how many documents were empty.
For example:

    SUMMARY OF DOCUMENTS DOWNLOADED
    -------------------------------
    Number of successful downloads:       170
    Number of unavailable documents:       23
    Number of empty documents:              7


Finally, we merge the event frames and documents using the command:

         perl merge_events.pl


--- Directory Structure ------

When this command has been run, the top level directory should consist
of:
        DIRECTORIES
        ./urls          contains text files containing urls and file names
        ./raw_html      raw downloaded html files
        ./clean_html    downloaded files with html stripped
        ./events        event frames
        ./merged_files  downloaded files merged with their associated
                        event frames
        ./information   provides details of the sources and topics of
                        documents
        ./pre_processing_scripts
        

        LOG FILES
        download_corpus_DOWNLOADED.log
        download_corpus_DOWNLOAD_UNAVAILABLE.log
        download_corpus_EMPTYFILE.log

        PERL SCRIPTS
        download_corpus.pl
        merge_events.pl
        summary.pl

        
