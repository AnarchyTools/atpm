#!/bin/bash
set -e

echo "**********THE ATPM TEST SCRIPT*************"

DIR="$(pwd)/$(dirname $0)"
ATPM="$(pwd)/.atllbuild/products/atpm"
pwd

#
# Simple dependency fetcher
#

pushd "$DIR/simple"

echo "*** Package info ***"
$ATPM info
if [ $? -ne 0 ] ; then
    echo "Test failed!"
    exit 1
fi

echo "*** Fetch deps ***"
$ATPM fetch
if [ $? -ne 0 ] ; then
    echo "Test failed!"
    exit 1
fi

echo "*** Update deps ***"
$ATPM update
if [ $? -ne 0 ] ; then
    echo "Test failed!"
    exit 1
fi

rm -rf external
popd

#
# Recursive dependency fetcher
#

# pushd "$DIR/recursive"

# echo "*** Package info ***"
# $ATPM info
# if [ $? -ne 0 ] ; then
#     echo "Test failed!"
#     exit 1
# fi

# echo "*** Fetch deps recursive***"
# $ATPM fetch
# if [ $? -ne 0 ] ; then
#     echo "Test failed!"
#     exit 1
# fi

# echo "*** Update deps recursive ***"
# $ATPM update
# if [ $? -ne 0 ] ; then
#     echo "Test failed!"
#     exit 1
# fi

# rm -rf external
# popd

echo "***ATPM TEST SCRIPT PASSED SUCCESSFULLY*****"