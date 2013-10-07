# gjp – Green Java Packager's tools

`gjp` (pronounced _/ˈdʒiː ˈaɪ ˈd͡ʒəʊ/_) is a set of tools to ease and partially automate Linux packaging of Java projects.

The project objective is to strongly reduce manual packaging efforts by enabling a new and much simpler workflow.

## Status

`gjp` is a research project currently in alpha state. Basic concepts seem to be viable, packages are currently being built with the new approach to identify problem areas but not all basic features have been coded yet. If you are a packager you can try to use it (any feedback would be **very** welcome!), but be warned that anything can still change at this point.

At the moment `gjp` is tested on openSUSE and can only output RPMs for the openSUSE and SLES distributions. Fedora, RHEL and other distros could be supported in the future.

## Contact

Are you using `gjp` or even just reading this? Let's get in touch!

    smoioli at suse dot de

## Requirements and installation

* [Ruby 1.9](https://www.ruby-lang.org/en/);
* [git](http://git-scm.com/);
* a JDK that can compile whatever software you need to package;
* only for the optional `set-up-nonet-user` subcommand, `sudo` and `iptables`;

You can install gjp via RubyGems:

    $ gem install gjp

## Workflow

Building a package with `gjp` is quite unusual — this is a [deliberate choice](#motivation) to minimize packaging efforts.

### Overview

The basic process is:

* a `gjp` project is created;
* sources are added to the project, `gjp` keeps track of them;
* any other file that is needed for the build, except the JDK, is added in binary form (jars, the Maven executable, its plugins,  etc.). Again, `gjp` keeps track of what you add, noting that those were binary build dependencies and not sources;
* a build is attempted. After the build is successful, `gjp` tracks which files were produced and restores sources in their original state, making it a "repeatable dry-run build". `gjp` also retains any files that were automatically downloaded by Maven or other similar tools during the dry-run as binary build dependencies;
* `gjp` produces spec files for two packages: one for the project itself and one for all of its binary build dependencies, called a **kit**;
* kit and project packages can be submitted to [OBS](http://en.opensuse.org/openSUSE:Build_Service). Project package will rebuild cleanly because it needs no Internet access - all files were already downloaded during the dry-run above and are included in the kit.

Note that:

* the project's build time dependency graph is very simple: just its kit and the JDK;
* the kit is basically a binary blob. If its sources are needed for proper packaging, for example to comply with the GPL, [a separate step](#kit-sources) is needed to add them;
* the kit is needed at build time only (by OBS), no end user should ever install it;
* a `gjp` project can be used to build a number of packages that share one binary kit. This can help if the kit becomes big in size;
* `gjp` will take advantage of Maven's pom files to generate its specs if they are available. This allows to precompile most spec fields automatically.

In `gjp`, the build process can be in one of the following phases at any given moment:

* **gathering**: in this phase you add sources and kit files. New projects start in this phase, you can always enter it later with `gjp gather`;
* **dry-running**: in this phase you attempt a build. Any change in the sources will be reverted after it ends, while files added to the kit will be retained. You can enter this phase with `gjp dry-run`;
* **finishing**: in this phase `gjp` generates specs and archive files. You can enter it running `gjp finish`;

### Sample project (commons-io)

#### Initialization and first gathering phase

Ceate a new `gjp` project, in this example named "galaxy":

    mkdir galaxy
    cd galaxy
    gjp init

`gjp init` automatically starts a new gathering phase in which you can add sources and kit files. It also generated a folder structure and assumes you respect it, in particular, you should place all your projects' source files in `src/`. Every `src/` subfolder will become a separate package named after the folder itself, so use the following commands to create a `commons-collections` folders and populate it:

    cd src
    mkdir commons-collections
    cd commons-collections
    wget http://archive.apache.org/dist/commons/collections/source/commons-collections-3.2.1-src.zip
    unzip commons-collections-3.2.1-src.zip
    rm commons-collections-3.2.1-src.zip

Now let's move to the kit (which, unsurprisingly, should be placed in the `kit/` directory). commons-collections needs Maven 3 to build, so we should simply unzip a copy in `kit/`:

    cd ../../kit
    wget http://apache.fastbull.org/maven/maven-3/3.1.0/binaries/apache-maven-3.1.0-bin.zip
    unzip apache-maven-3.1.0-bin.zip
    rm apache-maven-3.1.0-bin.zip
    cd ..

This is actually everything needed to do a first dry-run build.

#### First dry-run phase

Let's call `gjp dry-run` to let `gjp` know we are building and then call Maven. Note that `gjp mvn` is used instead of plain `mvn`: `gjp` will take care of locating the Maven installation in `kit/` and ensure it will store all downloaded files there.

    gjp dry-run
    cd src/commons-collections/commons-collections-3.2.1-src/
    gjp mvn package
    gjp finish

Success! At this point `gjp` took note of all needed files, and restored `src/` as it was before the build. Also note that build output files have been listed in `file_lists/commons-collections_output` and will be used later to compile the `%install` and `%files` sections of the project spec (by default only jar files are included).

This should be sufficient to be able to repeat the build on a machine with no Internet access, but what if we wanted to be 100% sure of that?

#### Second, networkless, dry-run phase

`gjp` has a subcommand to setup a `nonet` user without Internet access, courtesy of `iptables`. You can simply retry the build using that user to see if it works. Note that the following commands will alter group permissions to allow both your current user and `nonet` to work on the same files. 

    gjp set-up-nonet-user
    chmod -R g+rw ../../..
    gjp dry-run
    su nonet
    ping www.google.com #this should fail!
    gjp mvn package
    chmod -R g+rw .
    exit

The above is obviously not mandatory, but it can be useful for debugging purposes.

#### Second gathering phase: adding a build.sh file

One last thing before generating packages is to setup a build script. By default `gjp` will generate a spec file which assumes a `build.sh` script in the source folder of your project that contains all commands needed to build the package itself. At the moment, this needs to be done manually, but it will hopefully be automated in a future release.

Let's start a new gathering phase and add that:

    gjp gather
    vi ../build.sh

Add the following lines:

    #!/bin/sh
    cd src/commons-collections/commons-collections-3.2.1-src/
    ../../../kit/apache-maven-3.1.0/bin/mvn -Dmaven.repo.local=`readlink -e ../../../kit/m2` -s`readlink -e ../../../kit/m2/settings.xml` package

Note that `build.sh` gets called from the `gjp` project root, hence the `cd` line, and the Maven line was taken directly from `gjp mvn` output above and pasted verbatim.
Now complete the gathering:

    gjp finish
    cd ../../..

#### Generating archives and spec files

The following command will generate the kit spec:

    gjp generate-kit-spec
    less specs/galaxy-kit.spec

Nothing fancy here, the spec simply copies `kit/` contents in a special directory to be available for later compilation of packages.
You can also edit the spec file manually if you want. When you later regenerate it, `gjp` will automatically try to reconcile changes with a [three-way merge](http://en.wikipedia.org/wiki/Three-way_merge#Three-way_merge).

You can also generate the corresponding .tar.xz file with:

    gjp generate-kit-archive

The contents of this file were tracked by `gjp` during gathering and dry-run phases, and are listed in `file_lists/kit`. You can also edit it if you want.

You can then generate the project spec and archive files provided you have a pom file (more formats will be supported in future). In this case:

    gjp generate-package-spec commons-collections src/commons-collections/commons-collections-3.2.1-src/pom.xml
    gjp generate-package-archive commons-collections
    less specs/commons-collections.spec

commons-collection BuldRequires galaxy-kit, its archive contains only source files and it will install any produced .jar file in `/usr/lib/java`.

Packages are ready to be submitted to an OBS project. As OBS integration is not yet implemented, refer to OBS documentation to do that.

#### Kit sources

If kit sources are needed for license compliance, some extra work is needed. Fortunately, finding jar source files and adding them to the kit is much easier than packaging its contents in proper RPMs!

If the project you are packaging uses Maven, you can ask Maven itself to find source jars for dependencies. Running the following command will add them to the kit:

    gjp mvn dependency:sources

Unfortunately this will not take care of Maven itself, Maven's plugins and their dependencies so some extra work might be needed.

At the moment `gjp`'s supprort to kit source retrieval is limited to the following subcommands:

* `gjp get-pom NAME` will attempt to find a pom. `NAME` can be a jar file on your disk, a project directory, or simply a `name-version` string. `gjp` will get the pom either from the package itself or through search.maven.org using heuristic searching;
* `gjp get-parent-pom POM` will attempt to download a pom's parent from search.maven.org, where `POM` is a filename or URI;
* `gjp get-source-address POM` will attempt to find the SCM Internet address of a pom.xml from the file itself or through api.github.com. `POM` can either be a filename or a URI;
* `gjp get-source POM ADDRESS` downloads the source of a pom.xml's project from its SCM at ADDRESS;

More comprehensive support is planned in future releases.

You are advised to use [Maven Central](http://search.maven.org/) to search for sources and other information about projects.

### Troubleshooting

To know in which phase you are in, use `gjp status`.

`gjp` internally uses `git` to keep track of files, any gjp project is actually also a `git` repo. Feel free to navigate it, you can commit, push and pull freely as long as the `gjp` tags are preserved. You can also delete commits and tags, effectively rewiding gjp history (just make sure to delete all tags pointing to a certain commit when you discard it).

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

### Kit rationale

`gjp` simplifies the packaging process mostly because of its use of a binary blob package that contains all build time dependencies for a set of packages called a **kit**.

Building software from a binary blob is unusual for Linux distros, and it surely has some drawbacks. It is anyway believed that benefits outweigh them, in fact using prebuilt software:

* drastically reduces packaging efforts. A very basic and relatively simple package like [commons-collections](http://commons.apache.org/proper/commons-collections/) needs about [150 jars](https://build.opensuse.org/package/show/home:SilvioMoioli/galaxy-kit) just to be compiled and tested. Those should be packaged, roughly, one-by-one!
* is just the way all Java developers out there build, test and use their software — this is how they expect it to work. Any different approach is necessarily error-prone and could result in unexpected bugs;
* does not affect the ability of providing patches to Java projects, as only build time requirements are in the kit. In virtually all cases patching a piece of software does not require to patch its build toolchain;
* does not affect the ability of complying to software licenses like the GPL. In fact those licenses only require to redistribute a project's source code - not the whole toolchain needed to build it. [Sources can be added](#kit-sources) for GPL'd parts of the kit, if any.

## Sources

`gjp`'s Git repo is available on GitHub, which can be browsed at:

    https://github.com/SilvioMoioli/gjp

and cloned with:

    git clone git@github.com:SilvioMoioli/gjp.git

## License

MIT license.
