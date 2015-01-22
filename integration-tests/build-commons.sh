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
# simulate tetra generate-script
cd ../..
cat >packages/commons-collections/build.sh <<"EOF"
#!/bin/bash
PROJECT_PREFIX=`readlink -e .`
cd .
cd src/commons-collections-3.2.1-src/
$PROJECT_PREFIX/kit/apache-maven-3.2.5/bin/mvn -Dmaven.repo.local=$PROJECT_PREFIX/kit/m2 -s$PROJECT_PREFIX/kit/m2/settings.xml -o package -DskipTests
EOF

echo "**************** All Done ****************"

ls -lah *
