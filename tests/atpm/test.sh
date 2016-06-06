#!/bin/bash
set -e

echo "**********THE ATPM TEST SCRIPT*************"

DIR="$(pwd)/$(dirname $0)"
ATPM="$(pwd)/.atllbuild/products/atpm"
pwd

#
# Binary dependencies test
#
echo "*** Binary dependencies ***"

pushd "$DIR/binary"

# remove existing tarball, etc
rm -rf external

$ATPM fetch

echo "validating keys"
if ! grep "0.1" build.atlock; then
    echo "Failed to find locked version 0.1"
    exit 1
fi

if ! grep "https://github.com/AnarchyTools/dummyBinaryPackage/releases/download/0.1/osx.tar.xz" build.atlock; then
    echo "Failed to find expected URL"
    exit 1
fi

if ! grep "c8311dd51dfbdd6f76c312f660f208a163415e5e7fa9f8c87f82ecaf50e0378b" build.atlock; then
    echo "Failed to find expected shasum"
    exit 1
fi

popd

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

pushd "$DIR/recursive"

echo "*** Package info ***"
$ATPM info
if [ $? -ne 0 ] ; then
    echo "Test failed!"
    exit 1
fi

echo "*** Fetch deps recursive***"
$ATPM fetch
if [ $? -ne 0 ] ; then
    echo "Test failed!"
    exit 1
fi

$ATPM info
if [ $? -ne 0 ] ; then
    echo "Test failed!"
    exit 1
fi

echo "*** Update deps recursive ***"
$ATPM update
if [ $? -ne 0 ] ; then
    echo "Test failed!"
    exit 1
fi

rm -rf external
popd

echo "***ATPM TEST SCRIPT PASSED SUCCESSFULLY*****"