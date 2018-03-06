#!/usr/bin/perl -w

# author : Prashant Mathur
# this is alignment based recaser
# ALL CAPS, First caps (replace these)

# input from STDIN
# 1. SOURCE (TOKENIZED and CASED)
# 2. TARGET (TOKENIZED and RECASED)
# 3. ALIGNMENT
# 4. SOURCE ..

	# Agree and create account 
	# Aceptar y crear una cuenta
	# 0-0 1-1 2-2 3-3 3-4

# use this command (DO NOT LOWERCASE THE SOURCE TEXT)
# paste -d'\n' source.tokenized mtoutput alignment | perl alignment-based-recaser.pl > mtoutput.cased

use Switch;
use Data::Dumper;
use utf8;
binmode(STDOUT, ":utf8");
binmode(STDIN, ":utf8");
binmode(STDERR, ":utf8");

while($l1=<STDIN>){
	chop($l1);
	$l2=<STDIN>;
	chop($l2);
	$l3=<STDIN>;
	chop($l3);
	$l1 =~ s/\s\s*/ /g;
	@src = split(/ /, $l1);
	$l2 =~ s/\s\s*/ /g;
	@trg = split(/ /, $l2);
	$align = &read_align($l3);

	for ($i =0 ; $i<=$#trg; $i++){ # for all target words
		# compute alignment points for each target word
		next if($trg[$i] =~ m/\$[a-z]+/ || $trg[$i] !~ m/[a-z]/i);
		next if(!exists $align->{$i});
		next if(scalar(@{$align->{$i}}) > 1); # not touching the multiple aligned target words
		for $j (@{$align->{$i}}) {
			# check the source word with index $j
			next if($src[$j] =~ m/\$[a-z]+/ || $src[$j] !~ m/[a-z]/i);
			$pword = ""; # if the word is start of sentence
			$pword = $src[$j-1] if ($j > 0);
			$type = &check_caps($src[$j], $pword);
			switch($type){
				case 1	{ # all letters are caps
					$t = uc $trg[$i];
					$trg[$i] = $t;
				}
				case 2 { # first letter is caps
					$t = ucfirst lc($trg[$i]);
					$trg[$i] = $t;
				}
				case 3 { # all lowercase
					$t = lc $trg[$i];
					$trg[$i] = $t if ($i!=0 && $trg[$i-1] !~ m/./);
				}
			}	
		}
	}
# now capitalize all words after fullstop
	$l2 = join(" ", @trg);
	$l2 =~ s/([a-z]+) ([\.]) ([a-z]+)/$1 $2 \u$3/g;
# fix capitalization of sentences that start with wide character
	$l2 =~ s/^([\W]) ([a-z]+)/$1 \u$2/g;
	print $l2."\n";
}

sub read_align{
	$a=shift;
	%align=();
	@aligns = split(/ /, $a);
	for (@aligns){
		($key, $val) = split(/-/);
		push (@{$align{$val}}, $key);
	}
	return \%align;
}

sub check_caps{
	$str = shift; # current source word
	$pstr = shift; # previous source word
	return 4 if ($str =~ m/^&/i || length($str)==1); # skip all escaped entities &amp; &#234; and if the word is a single letter (ambiguous)
	return 1 if ($str eq uc $str);
	return 2 if ($str eq ucfirst(lc($str)) && $pstr !~ m/\./ && $pstr ne "");
#	return 3 if ($str eq lc $str);
	return 4;
}
