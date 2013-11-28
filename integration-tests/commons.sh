#!/bin/bash

# A crude integration test that builds commons-collections

rm -Rf galaxy
mkdir galaxy
cd galaxy
gjp init

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

gjp dry-run
cd src/commons-collections/commons-collections-3.2.1-src/
gjp mvn package -DskipTests
gjp finish

gjp generate-all
cd ../../..

cd src
mkdir commons-fileupload
cd commons-fileupload
wget http://mirror.nohup.it/apache//commons/fileupload/source/commons-fileupload-1.3-src.zip
unzip commons-fileupload-1.3-src.zip
rm commons-fileupload-1.3-src.zip

gjp dry-run
cd commons-fileupload-1.3-src/
gjp mvn package -DskipTests
gjp finish

gjp generate-kit-archive
gjp generate-kit-spec
gjp generate-package-script
gjp generate-package-archive
gjp generate-package-spec
cd ../../..


echo "**************** All Done ****************"

ls -lah output/*
