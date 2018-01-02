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

Regression Tests
================

To run regression tests you would need to download moses-regression-tests repository on your laptop

`git clone git@github.com:ebay-hlt/moses-regression-tests.git`

Then, copy the moses-regression-test directory to cluster (In my case, gridmaster)

`scp -r moses-regression-tests gridmaster:~/src/`

Then, inside mosesdecoder directory run the regression tests

`./compile.sh --with-regtest=~/src/moses-regression-tests --full`

