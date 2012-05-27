package C::Tokenize;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/tokenize
                decomment
                @fields
                $trad_comment_re
                $cxx_comment_re
                $comment_re
                $cpp_re
                $char_const_re
                $operator_re
                $number_re
                $word_re
                $grammar_re
                $single_string_re
                $string_re
                $reserved_re
               /;
use warnings;
use strict;
our $VERSION = 0.04;

my @reserved_words = sort {length $b <=> length $a} 
    qw/auto if break int case long char register continue return
       default short do sizeof double static else struct entry switch
       extern typedef float union for unsigned goto while enum void
       const signed volatile/;

my $reserved_words = join '|', @reserved_words;
our $reserved_re = qr/\b(?:$reserved_words)\b/;

our @fields = qw/comment cpp char_const operator grammar 
                 number word string reserved/;

    # Regular expression to match a /* */ C comment.

our $trad_comment_re = qr!
                            /\*
                            (?:
                                # Match "not an asterisk"
                                [^*]
                            |
                                # Match multiple asterisks followed
                                # by anything except an asterisk or a
                                # slash.
                                \*+[^*/]
                            )*
                            # Match multiple asterisks followed by a
                            # slash.
                            \*+/
                        !x;

# Regular expression to match a // C comment (C++-style comment).

our $cxx_comment_re = qr!//.*\n!;

# Master comment regex

our $comment_re = qr/
                       (?:
                           $trad_comment_re
                       |
                           $cxx_comment_re
                       )
                   /x;

# Regular expression to match a C preprocessor instruction.

our $cpp_re = qr/^\h*
                 \#
                 (?:
                    $trad_comment_re
                |
                    [^\\\n]
                |
                    \\[^\n]
                |
                    \\\n
                )+\n
               /mx;

# Regular expression to match a C character constant like 'a' or '\0'.
# This allows any \. expression at all.

our $char_const_re = qr/
                          '
                          (?:
                              .
                          |
                              \\.
                          )
                          '
                      /x;

# Regular expression to match one character operators

our $one_char_op_re = qr/(?:\%|\&|\+|\-|\=|\/|\||\.|\*|\:|>|<|\!|\?|~|\^)/;

# Regular expression to match all operators

our $operator_re = qr/
                        (?:
                                # Operators with two characters
                                \|\||&&|<<|>>|--|\+\+|->
                            |
                                # Operators with one or two characters
                                # followed by an equals sign.
                                (?:<<|>>|\+|-|\*|\/|%|&|\||\^)
                                =
                            |
                                $one_char_op_re
                            )
                    /x;

# Re to match a C number

our $decimal_re = qr/[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?l?/i;

our $hex_re = qr/0x[0-9a-f]+l?/i;

our $number_re = qr/
                      (?:
                          $hex_re
                      |
                          $decimal_re
                      )
                  /x;

# Re to match a C word

our $word_re = qr/[a-z_](?:[a-z_0-9]*)/i;

# Re to match C grammar

our $grammar_re = qr/[(){};,\[\]]/;

# Regular expression to match a C string.

our $single_string_re = qr/
                             (?:
                                 "
                                 (?:[^\\"]+|\\[^"]|\\")*
                                     "
                                     )
                         /x;


# Compound string regular expression.

our $string_re = qr/$single_string_re(?:\s*$single_string_re)*/;

# Master regular expression for tokenizing C text. This uses named
# captures.
    
our $c_re = qr/
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
                     (?<reserved>$reserved_re)
                 |
                     (?<word>$word_re)
                 |
                     (?<string>$string_re)
                 )
             /x;


sub decomment
{
    my ($comment) = @_;
    $comment =~ s/^\/\*(.*)\*\/$/$1/sm;
    return $comment;
}

sub tokenize
{
    my ($text) = @_;

    my @lines;

    @lines = get_lines ($text);

    my @tokens;

    my $line = 1;
    while ($text =~ /\G($c_re)/g) {
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
