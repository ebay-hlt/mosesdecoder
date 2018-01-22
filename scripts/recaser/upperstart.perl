#!/usr/bin/perl -w

use strict;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

while(<STDIN>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    my @WORD = split(/ /);
    &uppercase(\$WORD[0]);

    my $first = 1;
    foreach (@WORD) {
	print " " unless $first;
	$first = 0;
	print $_;
    }
    print "\n";
}

sub uppercase {
    my ($W) = @_;
    $$W = ucfirst($$W);
}

