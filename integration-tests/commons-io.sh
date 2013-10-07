#!/bin/bash

# A crude integration test that builds commons-lang

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
gjp mvn package
gjp finish

cd ../../..
cat >src/commons-collections/build.sh << "EOF"
#!/bin/sh
cd src/commons-collections/commons-collections-3.2.1-src/
../../../kit/apache-maven-3.1.0/bin/mvn -Dmaven.repo.local=`readlink -e ../../../kit/m2` -s`readlink -e ../../../kit/m2/settings.xml` package
EOF

gjp generate-kit-spec
gjp generate-kit-archive

gjp generate-package-spec commons-collections src/commons-collections/commons-collections-3.2.1-src/pom.xml
gjp generate-package-archive commons-collections

echo "All Done"