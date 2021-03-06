Mosesdecoder
============
This is the clone of mosesdecoder on github.com/ebay-hlt.


Original Version
================

The original version of this repository corresponds to commit 29bd94f94251fbe7c7d213404a1dd897ab054a98. This is accessible via 

https://github.com/ebay-hlt/mosesdecoder/commit/29bd94f94251fbe7c7d213404a1dd897ab054a98

Install dependencies
====================

First we need to install all dependencies:

`make -f contrib/Makefiles/install-dependencies.gmake`

Make sure of two things:
- The http port is open when you perform the above operation. 
- The machine you are using has Ubuntu14 release

Compile Moses
=============

Run `./compile.sh` to compile Moses, assuming all the dependencies are installed in your `opt/` folder.

Again, make sure that the machine you are installing Moses on has Ubuntu14 release.
Make sure your `Switch.pm` exists in your `PERL5LIB` path.

Regression Tests
================

To run regression tests you would need to download moses-regression-tests repository on your laptop

`git clone git@github.com:ebay-hlt/moses-regression-tests.git`

Then, copy the moses-regression-test directory to cluster (In my case, gridmaster)

`scp -r moses-regression-tests gridmaster:~/src/`

You can also skip the above two steps and use pramathur's regression test directory here:

`/vol/sdvol02/pramathur/src/moses-ebay/moses-regression-tests`

Once the regression tests directory is on cluster, hop inside the mosesdecoder directory and run the regression tests

`./compile.sh --with-regtest=~/src/moses-regression-tests --full`

`mosesserver` tests might fail because of uninstalled `XMLRPC::Lite` perl module. In that case, please install the module and set the `PERL5LIB` path and run the test again. 
