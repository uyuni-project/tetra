#!/bin/bash

# A crude integration test that builds some Apache Commons libraries

set -e

rm -Rf commons
mkdir commons
cd commons
tetra init

cd src
mkdir commons-collections
cd commons-collections
wget http://archive.apache.org/dist/commons/collections/source/commons-collections-3.2.1-src.zip
unzip commons-collections-3.2.1-src.zip
rm commons-collections-3.2.1-src.zip

cd ../../kit
wget http://apache.fastbull.org/maven/maven-3/3.1.1/binaries/apache-maven-3.1.1-bin.zip
unzip apache-maven-*.zip
rm apache-maven-*.zip
cd ..

tetra dry-run --very-very-verbose
cd src/commons-collections/commons-collections-3.2.1-src/
tetra mvn package -DskipTests
tetra finish

tetra generate-kit-archive
tetra generate-kit-spec
tetra generate-package-archive
tetra generate-package-spec
# simulate tetra generate-package-script
cat >../../../output/commons-collections/build.sh <<"EOF"
#!/bin/bash
PROJECT_PREFIX=`readlink -e .`
cd .
cd src/commons-collections/commons-collections-3.2.1-src/
$PROJECT_PREFIX/kit/apache-maven-3.1.1/bin/mvn -Dmaven.repo.local=$PROJECT_PREFIX/kit/m2 -s$PROJECT_PREFIX/kit/m2/settings.xml -o package -DskipTests
EOF

cd ../../..

cd src
mkdir commons-fileupload
cd commons-fileupload
wget http://archive.apache.org/dist/commons/fileupload/source/commons-fileupload-1.3-src.zip
unzip commons-fileupload-1.3-src.zip
rm commons-fileupload-1.3-src.zip

tetra dry-run
cd commons-fileupload-1.3-src/
tetra mvn package -DskipTests
tetra finish

tetra generate-kit-archive
tetra generate-kit-spec
tetra generate-package-archive
tetra generate-package-spec
# simulate tetra generate-package-script
cat >../../../output/commons-fileupload/build.sh <<"EOF"
#!/bin/bash
PROJECT_PREFIX=`readlink -e .`
cd .
cd src/commons-fileupload/commons-fileupload-1.3-src/
$PROJECT_PREFIX/kit/apache-maven-3.1.1/bin/mvn -Dmaven.repo.local=$PROJECT_PREFIX/kit/m2 -s$PROJECT_PREFIX/kit/m2/settings.xml -o package -DskipTests
EOF

cd ../../..


echo "**************** All Done ****************"

ls -lah output/*
