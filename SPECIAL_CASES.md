# Special cases

## Failing builds

If your build fails for whatever reason, abort it with `gjp finish --abort`. `gjp` will restore all project files as they were before build.

## Manual changes to generated files

You can do any manual changes to spec and build.sh files and regenerate them later, `gjp` will reconcile changes with a [three-way merge](http://en.wikipedia.org/wiki/Three-way_merge#Three-way_merge) and alert about any conflicts. You can generate single files with the following commands:

* `gjp generate-kit-archive`: (re)generates the kit tarball;
* `gjp generate-kit-spec`: (re)generates the kit spec;
* `gjp generate-package-script`: (re)generates the `build.sh` file from the latest bash history (assumes `gjp dry-run` and `gjp finish`have been used). Assumes your current working directory is in a package folder (that is, a subdirectory of `src/<package name>/`);
* `gjp generate-package-archive`: (re)generates a package tarball;
* `gjp generate-package-spec`: (re)generates a package spec;

Note that, by default, `generate-kit-archive` will generate additional "diff" tar.xz files instead of rewriting the whole archive - this will result in faster uploads if you use OBS (see below). You can use the `--full` option to regenerate a single complete archive.

## Kit sources

Your kit is basically a binary blob. If its sources are needed for proper packaging, for example to comply with the GPL, some extra steps are needed.

If you use Maven, most (~90%) sources can be automatically downloaded:

    gjp download-maven-source-jars

The remaining (mostly very outdated) jars will be listed by `gjp` when the download ends. You need to manually find corresponding sources for them, you can use:

    gjp get-source /path/to/<jar name>.pom

to get pointers to relevant sites if available in the pom itself.

A list of commonly used jars can be found [below](#frequently-used-sources).

You can also use:

    gjp list-kit-missing-sources

To get a list of jars that have one or more `.class` file which does not have a corresponding `.java` file in `kit/` (or zip files in `kit/`).

## Ant builds

`gjp` is currently optimized for Maven as it is the most common build tool, but it can work with any other. In particular, support for Ant has already been implemented and `gjp ant` works like `gjp mvn`.

Sometimes you will have jar files distributed along with the source archive that will end up in `src/`: you don't want that! Run

    gjp move-jars-to-kit

to have them moved to `kit/jars`. The command will generate a symlink back to the original, so builds will work as expected.

When generating spec files, be sure to have a `pom.xml` in your package directory even if you are not using Maven: `gjp` will automatically take advantage of information from it to compile many fields.

You can also ask `gjp` to find one via `gjp get-pom <filename>.jar` (be sure to have Maven in your kit).

## Other build tools

Other build tools are currently unsupported but will be added in the future. You can nevertheless use them - the only rule is that you have to keep all of their files in `kit`.

## [OBS](build.opensuse.org) integration

If you want to submit packages to OBS, you can do so by replacing the `output/` directory in your `gjp` project with a symlink to your OBS project directory.

Packages will rebuild cleanly in OBS because no Internet access is needed - all files were already downloaded during dry-run and are included in the kit.

Note that the kit package is needed at build time only by OBS, no end user should ever install it.


## Gotchas

* `gjp` internally uses `git` to keep track of files, any gjp project is actually also a `git` repo. Feel free to navigate it, you can commit, push and pull as long as the `gjp` tags are preserved. You can also delete commits and tags, effectively rewinding gjp history (just make sure to delete all tags pointing to a certain commit when you discard it);
* if your sources come from a Git repo, be sure to remove any `.git`/`.gitignore` files, otherwise `gjp` might get confused;
* if OBS complains that jars in your kit or package are compiled for a JDK version higher than 1.5, add the following line after `%install` to squelch the error:

    export NO_BRP_CHECK_BYTECODE_VERSION=true

* if packages build at first but then fail after a few days because Maven tries to connect to the Internet, add the `--option` flag to the `mvn` line in `build.sh`;
* if you want to be 100% sure your package builds without network access, you can use scripts in the `utils/` folder to create a special `nonet` user that cannot use the Internet and retry the build from that user.

## Frequently used sources

* antlr-2.7.7: `wget http://www.antlr2.org/download/antlr-2.7.7.tar.gz -O kit/m2/antlr/antlr/2.7.7/antlr-2.7.7-sources.tar.gz`;
* ant-launcher-1.6.5: sources included in ant-1.6.5;
* asm-3.3.1: `wget http://download.forge.ow2.org/asm/asm-3.3.1.tar.gz -O kit/m2/asm/asm/3.3.1/asm-3.3.1-sources.tar.gz`;
* jsr305-1.3.9: sources included in jar;
* jsr305-2.0.1: sources included in jar;
* commons-lang-1.0: `wget http://archive.apache.org/dist/commons/lang/source/lang-1.0-src.tar.gz -O kit/m2/commons-lang/commons-lang/1.0/commons-lang-1.0-sources.tar.gz`;
* commons-logging-api-1.1: `wget http://archive.apache.org/dist/commons/logging/source/commons-logging-1.1-src.tar.gz -O kit/m2/commons-logging/commons-logging/1.1/commons-logging-1.1-sources.tar.gz` (included in commons-logging-1.1);
* commons-logging-1.0: `wget http://archive.apache.org/dist/commons/logging/source/commons-logging-1.0-src.tar.gz -O kit/m2/commons-logging/commons-logging/1.0/commons-logging-1.0-sources.tar.gz`;
* dom4j-1.1: `wget http://dom4j.cvs.sourceforge.net/viewvc/dom4j/dom4j/?view=tar&pathrev=dom4j-1-1 -O kit/m2/dom4j/dom4j/1.1/dom4j-1.1-sources.tar.gz`;
* doxia-sink-api-1.0-alpha-4: use `svn export http://svn.apache.org/repos/asf/maven/doxia/doxia/tags/doxia-sink-api-1.0-alpha-4/ kit/m2/doxia/doxia-sink-api/1.0-alpha-4/doxia-sink-api-1.0-alpha-4-sources`;
* kxml2-2.2.2: use `wget http://sourceforge.net/projects/kxml/files/kxml2/2.2.2/kxml2-src-2.2.2.zip/download -O kit/m2/net/sf/kxml/kxml2/2.2.2/kxml2-2.2.2-sources.zip`;
* log4j-1.2.12: `wget http://archive.apache.org/dist/logging/log4j/1.2.12/logging-log4j-1.2.12.tar.gz -O kit/m2/log4j/log4j/1.2.12/log4j-1.2.12-sources.tar.gz`;
* stringtemplate-3.2: `wget http://www.stringtemplate.org/download/stringtemplate-3.2.tar.gz -O kit/m2/org/antlr/stringtemplate/3.2/stringtemplate-3.2-sources.tar.gz`;
* velocity-tools-2.0: `wget http://archive.apache.org/dist/velocity/tools/2.0/velocity-tools-2.0-src.tar.gz -O kit/m2/org/apache/velocity/velocity-tools/2.0/velocity-tools-2.0-sources.tar.gz`;
* velocity-1.5: `wget http://archive.apache.org/dist/velocity/engine/1.5/velocity-1.5.tar.gz -O kit/m2/org/apache/velocity/velocity/1.5/velocity-1.5-sources.tar.gz`;
* trilead-ssh2-build213-svnkit-1.3: `svn export http://svn.svnkit.com/repos/svnkit/tags/1.3.5/ kit/m2/org/tmatesoft/svnkit/svnkit/1.3.5/svnkit-1.3.5-sources` (included in svnkit 1.3.5 full sources because of custom patch);
* xercesImpl-2.9.1: `wget http://archive.apache.org/dist/xerces/j/source/Xerces-J-src.2.9.1.tar.gz -O kit/m2/xerces/xercesImpl/2.9.1/xercesImpl-2.9.1-sources.tar.gz`;
* xmlpull-1.1.3.1: wget `http://www.extreme.indiana.edu/xmlpull-website/v1/download/xmlpull_1_1_3_4c_src.tgz -O kit/m2/xmlpull/xmlpull/1.1.3.1/xmlpull-1.1.3.1-sources.tar.gz`
* xmlunit-1.3: `wget http://sourceforge.net/projects/xmlunit/files/xmlunit%20for%20Java/XMLUnit%20for%20Java%201.3/xmlunit-1.3-src.zip/download -O kit/m2/xmlunit/xmlunit/1.3/xmlunit-1.3-sources.zip`;
