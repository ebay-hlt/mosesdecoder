#!/usr/bin/perl -w

# $Id: consolidate-training-data.perl 928 2009-09-02 02:58:01Z philipp $

use strict;

my ($in,$out,$consolidated,@PART) = @ARGV;

`rm $consolidated.$in`  if -e "$consolidated.$in";
`rm $consolidated.$out` if -e "$consolidated.$out";
`rm $consolidated.weight` if -e "$consolidated.weight";

if (scalar @PART == 1) {
    my $part = $PART[0];
    `ln -s $part.$in $consolidated.$in`;
    `ln -s $part.$out $consolidated.$out`;
    `ln -s $part.weight $consolidated.weight` if(-e "$part.weight");
    exit;
}

foreach my $part (@PART) {
    die("ERROR: no part $part.$in or $part.$out") if (! -e "$part.$in" || ! -e "$part.$out");
    my $in_size = `cat $part.$in | wc -l`;
    my $out_size = `cat $part.$out | wc -l`;
    die("number of lines don't match: '$part.$in' ($in_size) != '$part.$out' ($out_size)") if $in_size != $out_size;
    if(-e "$part.weight")
    {
      my $weight_size = `cat $part.weight | wc -l`;
      die("number of lines don't match: '$part.$in' ($in_size) != '$part.weight' ($weight_size)") if $in_size != $weight_size;
      `cat $part.weight >> $consolidated.weight`;
    }
    else
    {
      `cat $part.$in | awk '{ print "1"; }' >> $consolidated.weight`;
    }
    `cat $part.$in >> $consolidated.$in`;
    `cat $part.$out >> $consolidated.$out`;
}

