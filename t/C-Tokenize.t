use warnings;
use strict;
use Test::More tests => 6;
BEGIN { use_ok('C::Tokenize') };
BEGIN { use_ok('C::Tokenize', '$trad_comment_re', 'decomment') };
use C::Tokenize 'tokenize';

my $tokens;

# Test for not eating subsequent text up to another comment.

my $long_comment =<<'EOF';
/****************************************************************************

  Globals read from font file

****************************************************************************/

char		hardblank;
int		charheight;
/* Bogus */
EOF

$tokens = tokenize ($long_comment);

my $found;

for my $token (@$tokens) {
    my $type = $token->{type};
    my $value = $token->{$type};
    if ($type ne 'comment' && $value =~ /charheight/) {
        $found = 1;
    }
}
ok ($found, "Parsing of long comments with multiple asterisks.");

# Test for comments within preprocessor instructions

my $cpp_comment =<<'EOF';
#define SMO_YES 1		/* use command-line smushmode, ignore font
				 * smushmode */
EOF
$tokens = tokenize ($cpp_comment);
ok (@$tokens == 1, "Comment in CPP with newline");

ok ($long_comment =~ /$trad_comment_re/);

my $stuff = "babu\nchabu";
my $comment = "/*$stuff*/";
my $decommented = decomment ($comment);

ok ($decommented eq $stuff, "Test decomment for multiline comments");

# Local variables:
# mode: perl
# End:
