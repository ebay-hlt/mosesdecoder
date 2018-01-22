#!/usr/bin/perl -w

use strict;

die("ERROR: syntax: run-command-on-multiple-refsets.perl <cmd> <in> [<in> <in> ...] <out>") 
    unless scalar @ARGV >= 3;

my $cmd = $ARGV[0];
my @inputfiles;
my $k=0;
for(my $i=1;$i<scalar(@ARGV)-1;$i++)
{
  $inputfiles[$k] = $ARGV[$i];
  $k++;
}
my $out = $ARGV[scalar(@ARGV)-1];

# my ($cmd,$in,$out) = @ARGV;

for(my $i=0;$i<scalar(@inputfiles);$i++)
{
  my $in = $inputfiles[$i];
  die("ERROR: attempt to run on multiple references, but there is only one")
    if -e $in && (! -e "$in.ref0" || -e $in."0");
  die("ERROR: did not find reference '$in.ref0' or '${in}0'")
    unless (-e "$in.ref0" || -e $in."0");
}

for(my $i=0;-e $inputfiles[0].".ref$i" || -e $inputfiles[0]."$i";$i++) {
    my $single_cmd = $cmd;
    my $list="";
    for(my $k=0;$k<scalar(@inputfiles);$k++)
    {
      my $in = $inputfiles[$k];
      if (! -e "$in.ref$i")
      {
        if(-e "$in$i") { $list .= " $in$i"; }
        else { $list .= " $in.ref0"; }
      }
      else { $list .= " $in.ref$i"; }
    }
    $list =~ s/^ //;
    $single_cmd =~ s/mref-input-file/$list/g;
    $single_cmd =~ s/mref-output-file/$out.ref$i/g;
    print STDERR "$single_cmd\n";
    system($single_cmd);
}
