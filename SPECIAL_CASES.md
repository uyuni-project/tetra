# Special cases

## Failing builds

If your build fails for whatever reason, abort it with `tetra finish --abort`. `tetra` will restore all project files as they were before build.

## Manual changes to generated files

You can do any manual changes to spec and build.sh files and regenerate them later, `tetra` will reconcile changes with a [three-way merge](http://en.wikipedia.org/wiki/Three-way_merge#Three-way_merge) and alert about any conflicts. You can generate single files with the following commands:

* `tetra generate-kit-archive`: (re)generates the kit tarball;
* `tetra generate-kit-spec`: (re)generates the kit spec;
* `tetra generate-package-script`: (re)generates the `build.sh` file from the latest bash history (assumes `tetra dry-run` and `tetra finish`have been used);
* `tetra generate-package-archive`: (re)generates the package tarball;
* `tetra generate-package-spec`: (re)generates the package spec;

## Kit sources

Your kit packages are basically binary blobs. If its sources are needed for proper packaging, for example to comply with the GPL, some extra steps are needed.

If you use Maven, most (~90%) sources can be automatically downloaded:

    tetra download-maven-source-jars

The remaining (mostly very outdated) jars will be listed by `tetra` when the download ends. You need to manually find corresponding sources for them, you can use:

    tetra get-source /path/to/<jar name>.pom

to get pointers to relevant sites if available in the pom itself.

A list of commonly used jars can be found [below](#frequently-used-sources).

You can also use:

    tetra list-kit-missing-sources

To get a list of jars that have one or more `.class` file which does not have a corresponding `.java` file in `kit/` (or zip files in `kit/`).

## Replacing kit packages

After you built a package, you might want to use it instead of some binary packages to build other ones.

`tetra` automatically creates some of the needed instructions inside of the spec file, you need to uncomment them and edit them manually to be fully functional.

## Ant builds

`tetra` is currently optimized for Maven as it is the most common build tool, but it can work with any other. In particular, support for Ant has already been implemented and `tetra ant` works like `tetra mvn`.

Sometimes you will have jar files distributed along with the source archive that will end up in `src/`: you don't want that! Run

    tetra move-jars-to-kit

to have them moved to `kit/jars`. The command will generate a symlink back to the original, so builds will work as expected.

When generating spec files, be sure to have a `pom.xml` in your package directory even if you are not using Maven: `tetra` will automatically take advantage of information from it to compile many fields.

You can also ask `tetra` to find one via `tetra get-pom <filename>.jar` (be sure to have Maven in your kit).

## Other build tools

Other build tools are currently unsupported but will be added in the future. You can nevertheless use them - the only rule is that you have to keep all of their files in `kit`.

## [OBS](build.opensuse.org) integration

If you want to submit packages to OBS, you can do so by replacing the `output/` directory in your `tetra` project with a symlink to your OBS project directory.

Packages will rebuild cleanly in OBS because no Internet access is needed - all files were already downloaded during dry-run and are included in the kit.

Note that the kit package is needed at build time only by OBS, no end user should ever install it.


## Gotchas

* `tetra` internally uses `git` to keep track of files, any tetra project is actually also a `git` repo. Feel free to navigate it, you can commit, push and pull as long as the `tetra` tags are preserved. You can also delete commits and tags, effectively rewinding tetra history (just make sure to delete all tags pointing to a certain commit when you discard it);
* some Maven plugins like the Eclipse Project ones ([Tycho](https://www.eclipse.org/tycho/)) will save data in `/tmp` downloaded from the Internet and will produce errors if this data is not there during offline builds. One way to work around that is to force Java to use a kit subdirectory as `/tmp`. Add the following option to `tetra mvn` during your build:

    -DskipTests=true -Djava.io.tmpdir=<full path to project>/kit/tmp

Use the following option in `mvn` in your build.sh file to make it reproducible:

    -DskipTests=true -Djava.io.tmpdir=$PROJECT_PREFIX/kit/tmp

* Tycho builds may also require NSS, so if you get NSS errors be sure to add `mozilla-nss` or an equivalent package in a BuildRequires: line;

* if you want to be 100% sure your package builds without network access, you can use scripts in the `utils/` folder to create a special `nonet` user that cannot use the Internet and retry the build from that user.

## Frequently used sources

* ant-1.8.1: `wget http://archive.apache.org/dist/ant/source/apache-ant-1.8.1-src.tar.gz -O kit/m2/org/apache/ant/ant/1.8.1/ant-1.8.1-sources.tar.gz`;
* ant-1.8.2: `wget http://archive.apache.org/dist/ant/source/apache-ant-1.8.2-src.tar.gz -O kit/m2/org/apache/ant/ant/1.8.2/ant-1.8.2-sources.tar.gz`;
* ant-launcher-<version>: sources included in ant-<version>;
* ant-nodeps-<version>: sources included in ant-<version>;
* antlr-2.7.7: `wget http://www.antlr2.org/download/antlr-2.7.7.tar.gz -O kit/m2/antlr/antlr/2.7.7/antlr-2.7.7-sources.tar.gz`;
* asm-3.3.1, asm-commons-3.3.1, asm-tree-3.3.1: `wget http://download.forge.ow2.org/asm/asm-3.3.1.tar.gz -O kit/m2/asm/asm/3.3.1/asm-3.3.1-sources.tar.gz`;
* aspectjrt-1.5.3: `wget http://git.eclipse.org/c/aspectj/org.aspectj.git/snapshot/org.aspectj-1_5_3_final.tar.gz -O kit/m2/aspectj/aspectjrt/1.5.3/aspectjrt-1.5.3-sources.tar.gz` (you can remove tests, lib, docs and org.eclipse.jdt.core);
* avalon-framework-4.1.5: `wget http://archive.apache.org/dist/avalon/avalon-framework/v4.1.5/avalon-framework-4.1.5.src.tar.gz -O kit/m2/avalon-framework/avalon-framework/4.1.5//4.1.5--sources.tar.gz`;
* batik-<subartifact>-1.7: `mkdir kit/m2/org/apache/xmlgraphics/batik/; wget http://archive.apache.org/dist/xmlgraphics/batik/batik-src-1.7.zip -O kit/m2/org/apache/xmlgraphics/batik/batik-sources.zip`
* bndlib-0.0.238, bndlib-0.0.255: these are used by apache-felix-1.4.x, which is in turn used by commons-parent < 22 to provide JDK 1.4 compatibility. Unfortunately no source before 1.1 is available, if possible update your dependencies to commons-parent >= 22;
* bsh-2.0b4: `wget http://beanshell2.googlecode.com/files/bsh-2.0b4-src.jar -O kit/m2/org/beanshell/bsh/2.0b4/bsh-2.0b4-sources.zip`;
* commons-beanutils-core-1.8.0: `wget http://archive.apache.org/dist/commons/beanutils/source/commons-beanutils-1.8.0-src.tar.gz -O kit/m2/commons-beanutils/commons-beanutils-core/1.8.0/commons-beanutils-core-1.8.0-sources.tar.gz`;
* commons-beanutils-core-1.8.3: `wget http://archive.apache.org/dist/commons/beanutils/source/commons-beanutils-1.8.3-src.tar.gz -O kit/m2/commons-beanutils/commons-beanutils-core/1.8.3/commons-beanutils-core-1.8.3-sources.tar.gz`;
* commons-codec-1.2: `wget http://archive.apache.org/dist/commons/codec/source/commons-codec-1.2-src.tar.gz -O kit/m2/commons-codec/commons-codec/1.2/commons-codec-1.2-sources.tar.gz`;
* commons-collections-testframework-3.2.1: included in commons-collections-3.2.1;
* commons-collections-2.0: `wget http://archive.apache.org/dist/commons/collections/source/collections-2.0-src.tar.gz -O kit/m2/commons-collections/commons-collections/2.0/commons-collections-2.0-sources.tar.gz`;
* commons-jexl-1.1: `wget http://archive.apache.org/dist/commons/jexl/source/commons-jexl-1.1-src.tar.gz -O kit/m2/commons-jexl/commons-jexl/1.1/commons-jexl-1.1-sources.tar.gz`;
* commons-lang-1.0: `wget http://archive.apache.org/dist/commons/lang/source/lang-1.0-src.tar.gz -O kit/m2/commons-lang/commons-lang/1.0/commons-lang-1.0-sources.tar.gz`;
* commons-logging-api-1.1: `wget http://archive.apache.org/dist/commons/logging/source/commons-logging-1.1-src.tar.gz -O kit/m2/commons-logging/commons-logging/1.1/commons-logging-1.1-sources.tar.gz` (included in commons-logging-1.1);
* commons-logging-1.0: `wget http://archive.apache.org/dist/commons/logging/source/logging-1.0-src.tar.gz -O kit/m2/commons-logging/commons-logging/1.0/commons-logging-1.0-sources.tar.gz`;
* derby-10.9.1.0: `wget http://archive.apache.org/dist/db/derby/db-derby-10.9.1.0/db-derby-10.9.1.0-src.tar.gz -O kit/m2/org/apache/derby/derby/10.9.1.0/derby-10.9.1.0-sources.tar.gz`;
* dom4j-1.1: `wget http://dom4j.cvs.sourceforge.net/viewvc/dom4j/dom4j/?view=tar\&pathrev=dom4j-1-1 -O kit/m2/dom4j/dom4j/1.1/dom4j-1.1-sources.tar.gz`;
* doxia-sink-api-1.0-alpha-4: use `svn export http://svn.apache.org/repos/asf/maven/doxia/doxia/tags/doxia-sink-api-1.0-alpha-4/ kit/m2/doxia/doxia-sink-api/1.0-alpha-4/doxia-sink-api-1.0-alpha-4-sources`;
* fop-0.95: `wget http://archive.apache.org/dist/xmlgraphics/fop/source/fop-0.95-src.tar.gz -O kit/m2/org/apache/xmlgraphics/fop/0.95/fop-0.95-sources.tar.gz`;
* hc-stylecheck-1: contains only metadata, no sources to be compiled in this artifact;
* jsr305-1.3.9, jsr305-2.0.1: sources included in jar;
* jsch-0.1.38: `wget http://sourceforge.net/projects/jsch/files/jsch/0.1.38/jsch-0.1.38.zip/download -O kit/m2/com/jcraft/jsch/0.1.38/jsch-0.1.38-sources.zip`;
* kxml2-2.2.2: use `wget http://sourceforge.net/projects/kxml/files/kxml2/2.2.2/kxml2-src-2.2.2.zip/download -O kit/m2/net/sf/kxml/kxml2/2.2.2/kxml2-2.2.2-sources.zip`;
* log4j-1.2.12: `wget http://archive.apache.org/dist/logging/log4j/1.2.12/logging-log4j-1.2.12.tar.gz -O kit/m2/log4j/log4j/1.2.12/log4j-1.2.12-sources.tar.gz`;
* naming-common-5.0.28, naming-java-5.0.28: `mkdir -p kit/m2/tomcat/tomcat/5.0.28/; wget http://archive.apache.org/dist/tomcat/tomcat-5/v5.0.28/src/jakarta-tomcat-5.0.28-src.tar.gz -O kit/m2/tomcat/tomcat/5.0.28/tomcat-5.0.28-sources.tar.gz` (part of tomcat);
* org.osgi.core-1.0.0: `wget http://archive.apache.org/dist/felix/org.osgi.core-1.0.0.tar.gz -O kit/m2/org/apache/felix/org.osgi.core/1.0.0/org.osgi.core-1.0.0-sources.tar.gz`;
* org.osgi.core-4.1.0: sources included in jar;
* org.osgi.service.obr-1.0.1: `wget http://archive.apache.org/dist/felix/org.osgi.service.obr-1.0.1-project.tar.gz -O kit/m2/org/apache/felix/org.osgi.service.obr/1.0.1/org.osgi.service.obr-1.0.1-sources.tar.gz`;
* plexus-utils-1.4.9: `wget https://github.com/sonatype/plexus-utils/archive/plexus-utils-1.4.9.tar.gz -O kit/m2/org/codehaus/plexus/plexus-utils/1.4.9/plexus-utils-1.4.9-sources.tar.gz`;
* spymemcached-2.6: `wget http://spymemcached.googlecode.com/files/memcached-2.4.2-sources.zip -O kit/m2/spy/spymemcached/2.6/spymemcached-2.6-sources.zip`;
* stringtemplate-3.2: `wget http://www.stringtemplate.org/download/stringtemplate-3.2.tar.gz -O kit/m2/org/antlr/stringtemplate/3.2/stringtemplate-3.2-sources.tar.gz`;
* velocity-tools-2.0: `wget http://archive.apache.org/dist/velocity/tools/2.0/velocity-tools-2.0-src.tar.gz -O kit/m2/org/apache/velocity/velocity-tools/2.0/velocity-tools-2.0-sources.tar.gz`;
* velocity-1.5: `wget http://archive.apache.org/dist/velocity/engine/1.5/velocity-1.5.tar.gz -O kit/m2/org/apache/velocity/velocity/1.5/velocity-1.5-sources.tar.gz`;
* trilead-ssh2-build213-svnkit-1.3: `svn export http://svn.svnkit.com/repos/svnkit/tags/1.3.5/ kit/m2/org/tmatesoft/svnkit/svnkit/1.3.5/svnkit-1.3.5-sources` (included in svnkit 1.3.5 full sources because of custom patch);
* xercesImpl-2.9.1: `wget http://archive.apache.org/dist/xerces/j/source/Xerces-J-src.2.9.1.tar.gz -O kit/m2/xerces/xercesImpl/2.9.1/xercesImpl-2.9.1-sources.tar.gz`;
* xercesMinimal-1.9.6.2: included in any xercesImpl >= 2 source package;
* xml-apis-ext-1.3.04: `wget http://archive.apache.org/dist/xml/commons/xml-commons-external-1.3.04-src.tar.gz -O kit/m2/xml-apis/xml-apis-ext/1.3.04/xml-apis-ext-1.3.04-sources.tar.gz`;
* xmlgraphics-commons-1.3.1: `wget http://archive.apache.org/dist/xmlgraphics/commons/source/xmlgraphics-commons-1.3.1-src.tar.gz -O kit/m2/org/apache/xmlgraphics/xmlgraphics-commons/1.3.1/xmlgraphics-commons-1.3.1-sources.tar.gz`;
* xmlpull-1.1.3.1: `wget http://www.extreme.indiana.edu/xmlpull-website/v1/download/xmlpull_1_1_3_4c_src.tgz -O kit/m2/xmlpull/xmlpull/1.1.3.1/xmlpull-1.1.3.1-sources.tar.gz`;
* xpp3-1.1.3.3: `wget http://www.extreme.indiana.edu/dist/java-repository/xpp3/distributions/xpp3-1.1.3.4.C_src.tgz -O kit/m2/xpp3/xpp3/1.1.3.3/xpp3-1.1.3.3-sources.tar.gz`;
* xmlunit-1.3: `wget http://sourceforge.net/projects/xmlunit/files/xmlunit%20for%20Java/XMLUnit%20for%20Java%201.3/xmlunit-1.3-src.zip/download -O kit/m2/xmlunit/xmlunit/1.3/xmlunit-1.3-sources.zip`;
