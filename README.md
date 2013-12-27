# gjp – Green Java Packager's tools

`gjp` is a set of tools to ease creating Linux packages for Java projects.

## Why?

Packaging of Java projects is sometimes hard because build tools like Maven partially overlap with distro tools like RPM in functionality.

We are trying to come up with **a tool that drastically simplifies packaging**.

## How to install?

First you need:

* [Ruby 1.9](https://www.ruby-lang.org/en/);
* [git](http://git-scm.com/);
* a JDK that can compile whatever software you need to package;
* only for the optional `set-up-nonet-user` subcommand, `sudo` and `iptables`.

You can install gjp via RubyGems:

    $ gem install gjp

## Workflow

Building a package with `gjp` is quite unusual — this is a [deliberate choice](#motivation), so don't worry. Basic steps are:

* `gjp init` a new project;
* add sources to `src/<package name>` and everything else you need in binary form in `kit/` (eg. a Maven binary distribution);
* execute `gjp dry-run`, any command needed to compile your software (possibly `gjp mvn package`), then `gjp finish`;
* execute `gjp generate-all`;
* done! Spec files and tarballs are baked in `output` automatically by `gjp`.

## How can that possibly work? (commons-collections walkthrough)

Let's review all steps in detail with a concrete Maven-based example, commons-collections.

First, ceate a new `gjp` project, in this example named "myproject":

    mkdir myproject
    cd myproject
    gjp init

(`gjp init` generates a folder structure for you).

Second, place all your projects' source files in `src/`. Every `src/` subfolder will become a separate package named after the folder itself, so use the following commands to create a `commons-collections` folders and populate it:

    cd src
    mkdir commons-collections
    cd commons-collections
    wget http://archive.apache.org/dist/commons/collections/source/commons-collections-3.2.1-src.zip
    unzip commons-collections-3.2.1-src.zip
    rm commons-collections-3.2.1-src.zip

Third, all non-source files needed for the build should go into `kit`. This includes all build dependencies and tools excluding the JDK, so in this case we need Maven:

    cd ../../kit
    wget http://www.eu.apache.org/dist/maven/binaries/apache-maven-3.1.1-bin.zip
    unzip apache-maven-3.1.1-bin.zip
    rm apache-maven-3.1.1-bin.zip

Fourth, you need to show `gjp` how to build your package by executing `gjp dry-run` and `gjp finish`. Bash history will be recorded to generate a build script (possibly only a starting point, maybe sufficient in simple cases):

    gjp dry-run
    cd src/commons-collections/commons-collections-3.2.1-src/
    gjp mvn package
    gjp finish

Note that we used `gjp mvn package` instead of `mvn package` so that `gjp` will use Maven from `kit/` instead of the system-wide installation you might have. `gjp` will also add some options on the mvn commandline so that any downloaded files will be retained in `kit/m2` so that this build can be replayed (even without network access) later. Also note that this being a dry-run build, sources will be brought back to their original state after `gjp finish`. This ensures build repeatability.

Finally, use this command to let `gjp` to generate build scripts, spec files and tarballs:

    gjp generate-all

Note that gjp will also generate a special binary-only package called a **kit**, which contains basically the `kit/` folder. This is the only build-time requirement of any `gjp` package in your project.

## Special cases

### Failing builds

If youyr build fails for whatever reason, abort it with `gjp finish --abort`. `gjp` will restore all project files as they were before build.

### Manual changes

You can do any manual changes to spec and build.sh files and regenerate them later, `gjp` will reconcile changes with a [three-way merge](http://en.wikipedia.org/wiki/Three-way_merge#Three-way_merge) and alert about any conflicts. You can generate single files with the following commands:

* `gjp generate-kit-archive`: (re)generates the kit tarball;
* `gjp generate-kit-spec`: (re)generates the kit spec;
* `gjp generate-package-script`: (re)generates the `build.sh` file from the latest bash history (assumes `gjp dry-run` and `gjp finish`have been used). Assumes your current working directory is in a package folder (that is, a subdirectory of `src/<package name>/`);
* `gjp generate-package-archive`: (re)generates a package tarball;
* `gjp generate-package-spec`: (re)generates a package spec;

Note that, by default, `generate-kit-archive` will generate additional "diff" tar.xz files instead of rewriting the whole archive - this will result in faster uploads if you use OBS (see below). You can use the `--full` option to regenerate a single complete archive.

### [OBS](build.opensuse.org)

If you want to submit packages to OBS, you can do so by replacing the `output/` directory in your `gjp` project with a symlink to your OBS project directory.

Packages will rebuild cleanly in OBS because no Internet access is needed - all files were already downloaded during dry-run and are included in the kit.

Note that the kit package is needed at build time only by OBS, no end user should ever install it.

### Kit sources

Your kit is basically a binary blob. If its sources are needed for proper packaging, for example to comply with the GPL, some extra steps are needed.

If you use Maven, most (~90%) sources can be automatically downloaded:

    gjp get-maven-source-jars

The remaining (mostly very outdated) jars will be listed by `gjp` when the download ends. You need to manually find corresponding sources for them, you can use:

    gjp get-source /path/to/<jar name>.pom

to get pointers to relevant sites if available in the pom itself.

A list of commonly used jars can be found [below](#frequently-used-jar-sources).

### Ant builds

`gjp` is currently optimized for Maven as it is the most common build tool, but it can work with any other. In particular, support for Ant has already been implemented and `gjp ant` works like `gjp mvn`.

Sometimes you will have jar files distributed along with the source archive that will end up in `src/`: you don't want that! Run

    gjp purge-jars

to have them moved to `kit/jars`. The command will generate a symlink back to the original, so builds will work as expected.

When generating spec files, be sure to have a `pom.xml` in your package directory even if you are not using Maven: `gjp` will automatically take advantage of information from it to compile many fields.

You can also ask `gjp` to find one via `gjp get-pom <filename>.jar` (be sure to have Maven in your kit).

### Other builds

Other build tools are currently unsupported but will be added in the future. You can nevertheless use them - the only rule is that you have to keep all of their files in `kit`.

### Optional: networkless dry-run builds

If you want to be 100% sure your package builds without network access, you can use a special `gjp` subcommand to setup a `nonet` user that cannot use the Internet. Then you can simply retry the build using that user to see if it works. Note that the following commands will alter group permissions to allow both your current user and `nonet` to work on the same files.

    gjp set-up-nonet-user
    chmod -R g+rw ../../..
    gjp dry-run
    su nonet
    ping www.google.com #this should fail!
    gjp mvn package
    chmod -R g+rw .
    exit
    gjp finish

### Gotchas

* `gjp` internally uses `git` to keep track of files, any gjp project is actually also a `git` repo. Feel free to navigate it, you can commit, push and pull as long as the `gjp` tags are preserved. You can also delete commits and tags, effectively rewinding gjp history (just make sure to delete all tags pointing to a certain commit when you discard it);
* if your sources come from a Git repo, be sure to remove any `.git`/`.gitignore` files, otherwise `gjp` might get confused;
* if OBS complains that jars in your kit or package are compiled for a JDK version higher than 1.5, add the following line after `%install` to squelch the error:

    export NO_BRP_CHECK_BYTECODE_VERSION=true

* if packages build at first but then fail after a few days because Maven tries to connect to the Internet, add the `--option` flag to the `mvn` line in `build.sh`;

### Frequently used jar sources

* ant-launcher-1.6.5: is included in ant-1.6.5 sources, you most prbably have it already in `kit/m2/ant/ant/1.6.5`;
* doxia-sink-api-1.0-alpha-4: use `svn checkout http://svn.apache.org/repos/asf/maven/doxia/doxia/tags/doxia-sink-api-1.0-alpha-4/ doxia-sink-api-1.0-alpha-4`;
* kxml2-2.2.2: use http://downloads.sourceforge.net/project/kxml/kxml2/2.2.2/kxml2-src-2.2.2.zip;

## Motivation

The Java developer world has packages (jars, wars, ears...), tools ([ant](http://ant.apache.org/), [Maven](http://maven.apache.org/), [Ivy](http://ant.apache.org/ivy/), [Gradle](http://www.gradle.org/)...) and established workflows to handle software distribution while Linux distros have their own ([zypper](http://en.opensuse.org/Portal:Zypper), [yum](http://en.wikipedia.org/wiki/Yellowdog_Updater,_Modified), [apt](http://en.wikipedia.org/wiki/Advanced_Packaging_Tool)...). Since the two communities have different goals and requirements, Linux distros typically want to repackage Java software with their own format, tools and workflows. Reasons range from ease of installation, predictable rebuildability, support to (security) patching, management tools, legal issues, etc.

Unfortunately those two "schemes" became very different over time, so automatic translation/repackaging is not possible except in very simple cases. This leads to a lot of tedious, error-prone manual work that Linux packagers have to do in order to fit the "alien" Java model into distro packaging rules that were thought and optimized with a different ecosystem in mind.

A typical example is packaging any software built by Maven on SUSE distros. A number of pain points arise:

* Maven requires Internet access and downloads precompiled code as part of the build. RPMs have to be built on a standalone machine in [OBS](http://en.opensuse.org/openSUSE:Build_Service), and they should build code from sources they are provided beforehands exclusively;
* [Maven is basically a plugin container](http://maven.apache.org/plugins/), so hundreds of different plugins have to be installed to build real-life projects (the exact plugin set and their dependencies is determined at build time). While this is no big deal for Java developers, since they get the corresponding jars prebuilt from Maven itself, it is a nightmare for distros, because all shipping code is supposed to be built from scratch and packaged!
* Maven often uses multiple versions of a same library or plugin during the same build. Usually distros do not maintain more than one version of any given library to reduce maintenance;
* Maven requires itself in order to build. To be more exact, Maven needs Nexus, which in turn needs Maven and Nexus. To be more exact, its build dependency graph is a very complicated mess with lots of cycles that have to be broken manually.

The current solution in openSUSE is having the packager handle those differences, but this limits the amount of software the community is able to package due to the high effort required to overcome them.

The Fedora community is experimenting with another set of tools, [XMvn](http://mizdebsk.fedorapeople.org/xmvn/site/), which goals are similar to `gjp`'s. 

## Kit rationale

`gjp` simplifies the packaging process mostly because of its use of a binary blob package that contains all build time dependencies for a set of packages called a **kit**.

Building software from a binary blob is unusual for Linux distros, and it surely has some drawbacks. It is anyway believed that benefits outweigh them, in fact using prebuilt software:

* drastically reduces packaging efforts. A very basic and relatively simple package like [commons-collections](http://commons.apache.org/proper/commons-collections/) needs about [150 jars](https://build.opensuse.org/package/show/home:SilvioMoioli/myproject-kit) just to be compiled and tested. Those should be packaged, roughly, one-by-one!
* is just the way all Java developers out there build, test and use their software — this is how they expect it to work. Any different approach is necessarily error-prone and could result in unexpected bugs;
* does not affect the ability of providing patches to Java projects, as only build time requirements are in the kit. In virtually all cases patching a piece of software does not require to patch its build toolchain;
* does not affect the ability of complying to software licenses like the GPL. In fact those licenses only require to redistribute a project's source code - not the whole toolchain needed to build it. [Sources can be added](#kit-sources) for GPL'd parts of the kit, if any.

## Status

`gjp` is a research project currently in beta state. If you are a packager you can try to use it, any feedback would be **very** welcome!

At the moment `gjp` is tested on openSUSE.


## Sources

`gjp`'s Git repo is available on GitHub, which can be browsed at:

    https://github.com/SilvioMoioli/gjp

and cloned with:

    git clone git@github.com:SilvioMoioli/gjp.git

## Contact

Are you using `gjp` or even just reading this? Let's get in touch!

    smoioli at suse dot de

## License

MIT license.
