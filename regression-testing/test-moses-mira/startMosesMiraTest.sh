#!/bin/bash

MYDIR=$( dirname ${BASH_SOURCE} )
MTSCIENCE=$( readlink -e ${MYDIR}/../../ )

cd $MYDIR
MOSESDIR=${MOSESDIR:-/home/$USER/src/mosesdecoder}

$MOSESDIR/scripts/training/mert-moses.pl \
    moses-mira.src.IN moses-mira.ref.IN2 $MOSESDIR/bin/moses moses-mira.ini.IN3 \
    --predictable-seeds \
    --maximum-iterations=5 \
    --no-filter-phrase-table \
    --nbestpostprocess $MTSCIENCE/regression-testing/test-moses-mira/postprocess.sh \
    --batch-mira \
    --return-best-dev 

exitCode=$?

if [ ${exitCode} -eq 0 ]; then
  grep -v "^# finished" mert-work/moses.ini | grep -v path | grep -v "# decoder" | sed 's/^# BLEU \([0-9].[0-9]*\) on dev .*/# BLEU \1 on dev/g' > moses-mira.OUT
else
  exit ${exitCode}
fi
