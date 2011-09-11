=head1 NAME

C::Tokenize - reduce a C file to a series of tokens

=cut

package C::Tokenize;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/tokenize @fields/;
use warnings;
use strict;
our $VERSION = 0.01;

my @reserved_words = sort {length $b <=> length $a} 
    qw/auto if break int case long char register continue return
       default short do sizeof double static else struct entry switch
       extern typedef float union for unsigned goto while enum void
       const signed volatile/;

my $reserved_words = join '|', @reserved_words;
my $reserved_re = qr/\b(?:$reserved_words)\b/;

our @fields = qw/comment cpp char_const operator grammar 
                 number word string/;

=head2 tokenize

    my $tokens = tokenize ($file);

Convert C<$file> into a series of tokens.

Each token contains

=over

=item leading

Leading whitespace

=item name

=item $name

The value of the type, e.g. C<$token->{comment}> if C<$token->{name}>
equals 'comment'.

=back

=cut

sub tokenize
{
    my ($text) = @_;

    my @lines;

    @lines = get_lines ($text);

    my @tokens;

    # Regular expression to match a /* */ C comment.

    my $trad_comment_re = qr!
                             /\*
                             (?:
                                 [^\*]
                             |
                                 \*+[^/]
                             )*
                             \*/
                         !x;

    # Regular expression to match a // C comment (C++-style comment).

    my $cxx_comment_re = qr!//.*\n!;

    # Master comment regex

    my $comment_re = qr/
                           (?:
                               $trad_comment_re
                           |
                               $cxx_comment_re
                           )
                       /x;

    # Regular expression to match a C preprocessor instruction

    my $cpp_re = qr/^\h*\#(?:
                        [^\\\n]+
                    |
                        \\[^\n]
                    |
                        \\\n
                    )+\n
                   /mx;

    # Regular expression to match a C character constant like 'a' or '\0'.
    # This allows any \. expression at all.

    my $char_const_re = qr/
                              '
                              (?:
                                  .
                              |
                                  \\.
                              )
                              '
                          /x;

    # Regular expression to match one character operators

    my $one_char_op = qr/(?:\%|\&|\+|\-|\=|\/|\||\.|\*|\:|>|<|\!|\?)/;

    # Regular expression to match all operators

    my $operator_re = qr/
                            (?:
                                \|\||&&|<<|>>
                            |
                                $one_char_op
                                =
                            |
                                $one_char_op
                            )
                        /x;

    # Re to match a C number

    my $decimal_re = qr/[0-9.e]+l?/i;

    my $hex_re = qr/0x[0-9a-f]+/i;

    my $number_re = qr/
                          (?:
                              $decimal_re
                          |
                              $hex_re
                          )
                      /x;

    # Re to match a C word

    my $word_re = qr/[a-z_](?:[a-z_0-9]*)/i;

    # Re to match C grammar

    my $grammar_re = qr/[(){};,\[\]]/;

    # Regular expression to match a C string.

    my $single_string_re = qr/
                          (?:
                              "
                              (?:[^\\"]+|\\[^"]|\\")*
                              "
                           )
                           /x;


    # Compound string regular expression.

    my $string_re = qr/$single_string_re(?:\s*$single_string_re)*/;

    # Master regular expression for tokenizing C text.
    
    my $c_re = qr/
                  (?<leading>\s+)?
                  (?:
                      (?<comment>$comment_re)
                  |
                      (?<cpp>$cpp_re)
                  |
                      (?<char_const>$char_const_re)
                  |
                      (?<operator>$operator_re)
                  |
                      (?<grammar>$grammar_re)
                  |
                      (?<number>$number_re)
                  |
                      (?<word>$word_re)
                  |
                      (?<string>$string_re)
                  )
                 /x;


#    print length $text, "\n";
#    print "$c_re\n";
    my $line = 1;
    while ($text =~ /\G($c_re)/g) {
#        print "ok\n";
        my $match = $1;
        if ($match =~ /^\s+$/s) {
            die "Bad match.\n";
        }
        while ($match =~ /\n/g) {
            $line++;
        }
        my %element;
        # Store the whitespace in front of the element.
        if ($+{leading}) {
            $element{leading} = $+{leading};
        }
        else {
            $element{leading} = '';
        }
        $element{line} = $line;
        my $matched;
        for my $field (@fields) {
            if (defined $+{$field}) {
                $element{type} = $field;
                $element{$field} = $+{$field};
                $matched = 1;
                last;
            }
        }
        if (! $matched) {
            die "Bad regex $line: '$match'\n";
        }

        push @tokens, \%element;
    }

    # Check the list of tokens for reserved words. If the word is
    # reserved, change its type and alter the field value.

    for my $token (@tokens) {
        if ($token->{type} eq 'word') {
            my $word = $token->{word};
            if ($word =~ $reserved_re) {
                $token->{type} = 'reserved';
                $token->{reserved} = $word;
                delete $token->{word};
            }
        }
    }
    return \@tokens;
}

sub get_lines
{
    my ($text) = @_;
    my @lines;
    my $start = 0;
    my $end;
    my $line = 1;
    while ($text =~ /\n/g) {
        $end = pos $text;
        $lines[$line] = {start => $start, end => $end};
        $line++;
        $start = $end + 1;
    }
    return @lines;
}

# get the line number of the start of the match of the regular
# expression in $text.

sub get_line_number
{
    my ($pos, $lines_ref) = @_;
    for my $line (1..$#$lines_ref + 1) {
        my $se = $lines_ref->[$line];
        if ($pos >= $se->{start} && $pos <= $se->{end}) {
            return $line;
        }
    }
    die "$pos outside bounds";
}


1;
