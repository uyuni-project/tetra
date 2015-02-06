#!/bin/bash

# A crude integration test that builds some Apache Commons libraries

set -ex

rm -Rf commons-collections
mkdir commons-collections
cd commons-collections
tetra init

cd src
unzip ../../commons-collections-3.2.1-src.zip 

tetra dry-run --very-very-verbose start
cd commons-collections-3.2.1-src/
tetra mvn --very-very-verbose package -DskipTests
tetra dry-run finish

tetra generate-kit
tetra generate-archive
tetra generate-spec

touch adding_patch_file
tetra patch "patch file added"
tetra generate-spec

echo "**************** All Done ****************"

ls -lah *
