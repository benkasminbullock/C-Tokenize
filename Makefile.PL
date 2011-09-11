use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/C/Tokenize.pm';

WriteMakefile (
    NAME => 'C::Tokenize',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
);
