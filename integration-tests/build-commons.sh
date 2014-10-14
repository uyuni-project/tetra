#!/bin/bash

# A crude integration test that builds some Apache Commons libraries

set -ex

rm -Rf commons-collections
mkdir commons-collections
cd commons-collections
tetra init

cd kit
unzip ../../apache-maven-3.1.1-bin.zip

cd ../src
unzip ../../commons-collections-3.2.1-src.zip 

tetra dry-run --very-very-verbose
cd commons-collections-3.2.1-src/
tetra mvn package -DskipTests
tetra finish

tetra generate-kit-archive
tetra generate-kit-spec
tetra generate-package-archive
tetra generate-package-spec
# simulate tetra generate-package-script
cd ../..
cat >src/build.sh <<"EOF"
#!/bin/bash
PROJECT_PREFIX=`readlink -e .`
cd .
cd src/commons-collections-3.2.1-src/
$PROJECT_PREFIX/kit/apache-maven-3.1.1/bin/mvn -Dmaven.repo.local=$PROJECT_PREFIX/kit/m2 -s$PROJECT_PREFIX/kit/m2/settings.xml -o package -DskipTests
EOF

echo "**************** All Done ****************"

ls -lah *
