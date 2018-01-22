#!/usr/bin/env perl
#
# This file is part of moses.  Its use is licensed under the GNU Lesser General
# Public License version 2.1 or, at your option, any later version.

# $Id$
use warnings;
use strict;
use FindBin qw($Bin);
use Getopt::Long "GetOptions";

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

# apply switches
my ($DIR,$CORPUS,$SCRIPTS_ROOT_DIR,$CONFIG,$HELP,$ERROR);
my $LM = "KENLM"; # KENLM is default.
my $BUILD_LM = "build-lm.sh";
my $NGRAM_COUNT = "ngram-count";
my $KENLM_DIR = dirname("$0") . "/../../bin";
my $KENLM_MEM = "80%";
my $KENLM_TYPE = "probing";
my $TMPDIR = $ENV{"TMPDIR"};
my $TRAIN_SCRIPT = "train-factored-phrase-model.perl";
my $MAX_LEN = 1;
my $FIRST_STEP = 1;
my $LAST_STEP = 11;
$ERROR = "training Aborted."
    unless &GetOptions('first-step=i' => \$FIRST_STEP,
                       'last-step=i' => \$LAST_STEP,
                       'corpus=s' => \$CORPUS,
                       'config=s' => \$CONFIG,
                       'dir=s' => \$DIR,
                       'ngram-count=s' => \$NGRAM_COUNT,
                       'build-lm=s' => \$BUILD_LM,
                       'kenlm-dir=s' => \$KENLM_DIR,
                       'kenlm-mem=s' => \$KENLM_MEM,
                       'kenlm-type=s' => \$KENLM_TYPE,
                       'lm=s' => \$LM,
                       'train-script=s' => \$TRAIN_SCRIPT,
                       'scripts-root-dir=s' => \$SCRIPTS_ROOT_DIR,
                       'max-len=i' => \$MAX_LEN,
                       'help' => \$HELP);

# check and set default to unset parameters
$ERROR = "please specify working dir --dir" unless defined($DIR) || defined($HELP);
$ERROR = "please specify --corpus" if !defined($CORPUS) && !defined($HELP) 
                                  && $FIRST_STEP <= 2 && $LAST_STEP >= 1;

my $KENLM_OPTS = "probing";
if ( $KENLM_TYPE =~ /trie/ ) {
   $KENLM_OPTS = "trie";
}
if ( $KENLM_TYPE =~ /-q(\d+)/ ) {
   $KENLM_OPTS .= " -q " . $1;
}
if ( $KENLM_TYPE =~ /-a(\d+)/ ) {
   $KENLM_OPTS .= " -a " . $1;
}

if ($HELP || $ERROR) {
    if ($ERROR) {
        print STDERR "ERROR: " . $ERROR . "\n";
    }
    print STDERR "Usage: $0 --dir /output/recaser --corpus /Cased/corpus/files [options ...]";

    print STDERR "\n\nOptions:
  == MANDATORY ==
  --dir=dir                 ... outputted recaser directory.
  --corpus=file             ... inputted cased corpus.

  == OPTIONAL ==
  = Recaser Training configuration =
  --train-script=file       ... path to the train script (default: train-factored-phrase-model.perl in \$PATH).
  --config=config           ... training script configuration.
  --scripts-root-dir=dir    ... scripts directory.
  --max-len=int             ... max phrase length (default: 1).

  = Language Model Training configuration =
  --lm=[IRSTLM,SRILM,KENLM] ... language model (default: KENLM).
  --build-lm=file           ... path to build-lm.sh if not in \$PATH (used only with --lm=IRSTLM).
  --ngram-count=file        ... path to ngram-count.sh if not in \$PATH (used only with --lm=SRILM).
  --kenlm-dir=path          ... path with lmplz/build_binary (used only with --lm=KENLM).
  --kenlm-mem=mem           ... memory to reserve for KenLM binaries (% or G).
  --kenlm-type=type         ... KenLM type. One of 'probing', 'trie', 'trie-a22', 'trie-q8', 'trie-q8-a22'

  = Steps this script will perform =
  (1) Truecasing;
  (2) Language Model Training;
  (3) Data Preparation
  (4-10) Recaser Model Training;
  (11) Cleanup.
  --first-step=[1-11]       ... step where script starts (default: 1).
  --last-step=[1-11]        ... step where script ends (default: 11).

  --help                    ... this usage output.\n";
  if ($ERROR) {
    exit(1);
  }
  else {
    exit(0);
  }
}

# main loop
`mkdir -p $DIR`;
&truecase()           if $FIRST_STEP == 1;
$CORPUS = "$DIR/aligned.truecased" if (-e "$DIR/aligned.truecased");
&train_lm()           if $FIRST_STEP <= 2;
&prepare_data()       if $FIRST_STEP <= 3 && $LAST_STEP >= 3;
&train_recase_model() if $FIRST_STEP <= 10 && $LAST_STEP >= 3;
&cleanup()            if $LAST_STEP == 11;

exit(0);

### subs ###

sub truecase {
    print STDERR "(1) Truecase data @ ".`date`;
    print STDERR "(1) To build model without truecasing, use --first-step 2, and make sure $DIR/aligned.truecased does not exist\n";

    my $cmd = "$Bin/train-truecaser.perl --model $DIR/truecaser_model --corpus $CORPUS";
    print STDERR $cmd."\n";
    system($cmd) == 0 || die("Training truecaser died with error " . ($? >> 8) . "\n");

    $cmd = "$Bin/truecase.perl --model $DIR/truecaser_model < $CORPUS > $DIR/aligned.truecased";
    print STDERR $cmd."\n";
    system($cmd) == 0 || die("Applying truecaser died with error " . ($? >> 8) . "\n");

}

sub train_lm {
    print STDERR "(2) Train language model on cased data @ ".`date`;
    my $cmd = "";
    if (uc $LM eq "IRSTLM") {
        $cmd = "$BUILD_LM -s improved-kneser-ney -i $CORPUS -n 3 -o $DIR/cased.irstlm.gz";
    }
    elsif (uc $LM eq "IRSTLM") {
        $LM = "SRILM";
        $cmd = "$NGRAM_COUNT -text $CORPUS -lm $DIR/cased.srilm.gz -interpolate -kndiscount";
    }
    elsif (uc $LM eq "KENLM") {
        $LM = "KENLM";
        $cmd = "$KENLM_DIR/lmplz -T $TMPDIR --memory $KENLM_MEM --text $CORPUS --arpa $DIR/cased.arpa --order 3 && $KENLM_DIR/build_binary -T $TMPDIR -S $KENLM_MEM $KENLM_OPTS $DIR/cased.arpa $DIR/cased.ken ; gzip -f $DIR/cased.arpa";
    }
    else {
        print STDERR "** Unknown LM type: $LM **" . "\n";
        exit(-1);
    }
    print STDERR "** Using $LM **" . "\n";
    print STDERR $cmd."\n";
    system($cmd) == 0 || die("Language model training failed with error " . ($? >> 8) . "\n");
}

sub prepare_data {
    print STDERR "\n(3) Preparing data for training recasing model @ ".`date`;
    open(CORPUS,$CORPUS);
    binmode(CORPUS, ":utf8");
    open(CASED,">$DIR/aligned.cased");
    binmode(CASED, ":utf8");
    print "$DIR/aligned.lowercased\n";
    open(LOWERCASED,">$DIR/aligned.lowercased");
    binmode(LOWERCASED, ":utf8");
    open(ALIGNMENT,">$DIR/aligned.a");
    my $skipped = 0;
    my $max_len = 2000;
    while(<CORPUS>) {
	if (length($_) > $max_len) {
          $skipped++;
          next;
        }
	s/\x{0}//g;
	s/\|//g;
	s/ +/ /g;
	s/^ //;
	s/ [\r\n]*$/\n/;
	next if /^$/;
	print CASED $_;
	print LOWERCASED lc($_);
	my $i=0;
	foreach (split) {
	    print ALIGNMENT "$i-$i ";
	    $i++;
	}
	print ALIGNMENT "\n";
    }
    if ($skipped > 0) {
      print STDERR "warning: skipped $skipped entries of length >$max_len\n";
    }
    close(CORPUS);
    close(CASED);
    close(LOWERCASED);
    close(ALIGNMENT);
}

sub train_recase_model {
    my $first = $FIRST_STEP;
    $first = 4 if $first < 4;
    print STDERR "\n(4) Training recasing model @ ".`date`;
    my $cmd = "$TRAIN_SCRIPT --root-dir $DIR --model-dir $DIR --first-step $first --alignment a --corpus $DIR/aligned --f lowercased --e cased --max-phrase-length $MAX_LEN";
    if (uc $LM eq "IRSTLM") {
        $cmd .= " --lm 0:3:$DIR/cased.irstlm.gz:1";
    }
    elsif (uc $LM eq "SRILM") {
        $cmd .= " --lm 0:3:$DIR/cased.srilm.gz:8";
    }
    else {
        $cmd .= " --lm 0:3:$DIR/cased.kenlm:8";
    }
    $cmd .= " -config $CONFIG" if $CONFIG;
    print STDERR $cmd."\n";
    system($cmd) == 0 || die("Recaser model training failed with error " . ($? >> 8) . "\n");
}

sub cleanup {
    print STDERR "\n(11) Cleaning up @ ".`date`;
    `rm -f $DIR/extract*`;
    my $clean_1 = $?;
    `rm -f $DIR/aligned*`;
    my $clean_2 = $?;
    `rm -f $DIR/lex*`;
    my $clean_3 = $?;
    `rm -f $DIR/truecaser_model`;
    my $clean_4 = $?;
    if ($clean_1 + $clean_2 + $clean_3 + $clean_4 != 0) {
        print STDERR "Training successful but some files could not be cleaned.\n";
    }
}
