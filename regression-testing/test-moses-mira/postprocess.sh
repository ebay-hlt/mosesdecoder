#! /bin/bash

cat $1 | sed 's/ /  /g' | sed 's/ AAA //g' | sed 's/^AAA //' | sed 's/ AAA$//' | sed 's/^AAA$//' | sed 's/  / /g'