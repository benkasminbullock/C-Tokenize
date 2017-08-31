use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Perl::Build 'get_info';
use Perl::Build::Pod ':all';
my $info = get_info (base => "$Bin/..");
my $filepath = "$Bin/../$info->{pod}";
my $errors = pod_checker ($filepath);
ok (@$errors == 0, "No errors");
if (@$errors > 0) {
    for (@$errors) {
	note "$_";
    }
}
my $linkerrors = pod_link_checker ($filepath);
ok (@$linkerrors == 0, "No link errors");
if (@$linkerrors > 0) {
    for (@$linkerrors) {
	note "$_";
    }
}
done_testing ();
