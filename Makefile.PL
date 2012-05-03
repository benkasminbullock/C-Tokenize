use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/C/Tokenize.pm';
my $repo = 'https://github.com/benkasminbullock/C-Tokenize';

WriteMakefile (
    NAME => 'C::Tokenize',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
);
