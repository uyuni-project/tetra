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
wget http://apache.fastbull.org/maven/maven-3/3.1.0/binaries/apache-maven-3.1.0-bin.zip
unzip apache-maven-3.1.0-bin.zip
rm apache-maven-3.1.0-bin.zip
cd ..

gjp dry-run
cd src/commons-collections/commons-collections-3.2.1-src/
gjp mvn package -DskipTests
cd ../../..
gjp finish

gjp generate-kit-archive
gjp generate-kit-spec

gjp generate-package-archive commons-collections
gjp generate-package-spec commons-collections src/commons-collections/commons-collections-3.2.1-src/pom.xml


cd src
mkdir commons-fileupload
cd commons-fileupload
wget http://mirror.nohup.it/apache//commons/fileupload/source/commons-fileupload-1.3-src.zip
unzip commons-fileupload-1.3-src.zip
rm commons-fileupload-1.3-src.zip

gjp dry-run
cd commons-fileupload-1.3-src/
gjp mvn package -DskipTests
cd ../../..
gjp finish

gjp generate-kit-archive -i
gjp generate-kit-spec

gjp generate-package-archive commons-fileupload
gjp generate-package-spec commons-fileupload src/commons-fileupload/commons-fileupload-1.3-src/pom.xml


echo "**************** All Done ****************"

ls -lah output/*