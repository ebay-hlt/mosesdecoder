#!/bin/bash
# 
# simple regression test suite for various scripts in the MTScience repo
# see *.test files in the directory on how to create own tests

BASEDIR="$( dirname ${BASH_SOURCE} )/../"

source $BASEDIR/Commons/bashlib/bashlib.sh

setUsage "MTScience script regression test suite.\nusage: "`basename $0`" [options]\n\nOptions:\n"
addOption -f --format    dest=FORMAT    default="TERMINAL" help="Output format, out of HTML, MARKDOWN, TERMINAL"
addOption -d --dir       dest=TEST_DIR  default="${BASEDIR}/regression-testing" help="directory containing test templates"
addOption -n --test-name dest=TEST_NAME default="*"  help="specify which test you want to run. omit for \"all\""
addOption -q --quiet     dest=QUIET     flagTrue     help="Set output verbosity to only error files"
addOption -v --verbose   dest=DEBUG     flagTrue     help="Set output verbosity to debug mode"
addOption -m --max-lines dest=MAX_LINES default="10" help="no. of lines a diff should output on failure (default: 10)"

parseOptions "$@"

# this function is mandatory to call at the beginning. The regressionTest functions
# make use of the bashlib/report library, so it supports all of their formats
REGRESSION_TEST_START "${FORMAT}"

# set the output verbosity level. If both options are given... well... then trust the debug
[[ "$QUIET" == "true" ]] && REGRESSION_TEST_SET_VERBOSITY ${REGRESSION_TEST_VERBOSITY_ERROR}
[[ "$DEBUG" == "true" ]] && REGRESSION_TEST_SET_VERBOSITY ${REGRESSION_TEST_VERBOSITY_DEBUG}

# the tests below will fail sometimes. This is how much output we will see
REGRESSION_TEST_SET_MAX_DIFF "${MAX_LINES}"

while read REGTEST; do
    . $REGTEST
done < <( find ${TEST_DIR} -name "${TEST_NAME%%.regTest}.regTest" ) 

while read TEST; do
    . $TEST
    TESTNAME=`basename $TEST .test`

    REGRESSION_TEST_NEW_GROUP "${TESTNAME}"

    # we better remember the current directory in case that the test changes stuff
    currentDirectory=$(pwd -P)

    REGRESSION_TEST_ASSERT_RAISE "EXEC: ${TESTDESCRIPTION}" "$TESTTEMPLATE 2> $TESTFILEPREFIX.STDERR"
    
    # return to directory we were in before invokation, if necessary
    cd "${currentDirectory}"
    REGRESSION_TEST_DIFF_FILES "DIFF: ${TESTDESCRIPTION}" "$TESTFILEPREFIX.OUT" "$TESTFILEPREFIX.REF" "${DIFFIGNORE}"

    REGRESSION_TEST_END

done < <( find ${TEST_DIR} -name "${TEST_NAME}.test" )
