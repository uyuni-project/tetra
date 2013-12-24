# gjp – Green Java Packager's tools

`gjp` (pronounced _/ˈdʒiː ˈaɪ ˈd͡ʒəʊ/_) is a set of tools to ease and partially automate Linux packaging of Java projects.

The project objective is to strongly reduce manual packaging efforts by enabling a new and much simpler workflow.

## Status

`gjp` is a research project currently in beta state. All basic features have been coded, non-essential ones are being planned, packages are currently being built. If you are a packager you can try to use it, any feedback would be **very** welcome!

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
* package sources are added in `src/<package name>`;
* any other file that is needed for the build, except the JDK, is added in binary form (jars, the Maven executable, plugins,  etc.) in `kit/`. In `gjp` a **kit** is a set of binary files that satisfies all build dependencies in a `gjp` project;
* a build is attempted and during the build, `gjp` keeps track of file changes. When it finishes, `gjp` restores `src/` in its original state, making it a "repeatable dry-run build". `gjp` will retain any files that were automatically downloaded by Maven or other similar tools in `kit/`, along with other binary build dependencies, and note any produced file for later spec generation;
* `gjp` produces spec files for two packages: one for the project itself and one for the kit needed to build it;
* kit and project packages can be submitted to [OBS](http://en.opensuse.org/openSUSE:Build_Service). Project package will rebuild cleanly because it needs no Internet access - all files were already downloaded during the dry-run phase above and are included in the kit.

Note that:

* the project's build time dependency graph is very simple: just its kit and the JDK;
* the kit is basically a binary blob. If its sources are needed for proper packaging, for example to comply with the GPL, [a separate step](#kit-sources) is needed to add them;
* the kit is needed at build time only (by OBS), no end user should ever install it;
* a `gjp` project can be used to build a number of packages that share one binary kit. This can help if the kit becomes big in size;
* `gjp` will take advantage of Maven's pom files to generate its specs if they are available. This allows to precompile most spec fields automatically.

### A sample Maven project (commons-collections)

#### Initialization and project setup

Ceate a new `gjp` project, in this example named "galaxy":

    mkdir galaxy
    cd galaxy
    gjp init

`gjp init` generates a folder structure and assumes you respect it, in particular, you should place all your projects' source files in `src/`. Every `src/` subfolder will become a separate package named after the folder itself, so use the following commands to create a `commons-collections` folders and populate it:

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

#### First dry-run build

Let's call `gjp dry-run` to let `gjp` know we are building and then call Maven. Note that `gjp mvn` is used instead of plain `mvn`: `gjp` will take care of locating the Maven installation in `kit/` and ensure it will store all downloaded files there.

    gjp dry-run
    cd src/commons-collections/commons-collections-3.2.1-src/
    gjp mvn package

Success! Now we have to tell gjp to return in normal mode:

    gjp finish

At this point `gjp` restored `src/` as it was before the build while taking note of any produced file, so that later it will be able to output `%install` and `%files` sections of the project spec file automatically.

Note that, if the build was unsusccesful, the following command can be used to cancel it and return to pre-dry running state:

    gjp finish --abort

#### Generating a build script

`gjp` expects that all commands needed to build a package are in a `build.sh` script in `src/<package name>`. If you are a Bash user you are lucky - `gjp` can create one for you by looking at your command history! Just type:

    gjp generate-package-script

Note that `gjp` will substitute the `gjp mvn` calls with equivalent lines that are actually runnable on a build host without `gjp` itself.

Of course this script can also be manually modified, and it must be in more difficult cases. You don't even have to be afraid of regenerating it later. `gjp` will run a three-way merge and warn if conflicts arise!

#### Generating archives and spec files

The following command will generate the kit archive in `output/galaxy-kit/`:

    gjp generate-kit-archive

Note that, in later runs, only an additional "diff" tar.xz file will be created to ease uploads. You can use the `--full` option to regenerate a single complete archive.

The following command will generate the kit spec:

    gjp generate-kit-spec

You can inspect the generated "galaxy-kit.spec" file, but in general you should not need to edit it.

You can then generate the project spec and archive files provided you have a pom file (more formats will be supported in future). In this case:

    gjp generate-package-archive
    gjp generate-package-spec
    less ../commons-collections.spec

commons-collection BuldRequires galaxy-kit, its archive contains only source files and it will install any produced .jar file in `/usr/lib/java`.
You can also edit the specs file manually if you want. When you later regenerate it, `gjp` will automatically try to reconcile changes with a [three-way merge](http://en.wikipedia.org/wiki/Three-way_merge#Three-way_merge).

OBS users: note that the output/ directory created by gjp can be submitted or used as OBS project. Feel free to replace it with a symlink pointing at your home OBS project, or use symlinks from your OBS project to its contents.

#### Quicker workflow

`gjp` also has a `generate-all` subcommand that will generate everything in one step. Thus, for Maven-based projects, the minimal workflow is:

    cd src
    mkdir <package_name>
    cd <package_name>
    wget <sources>
    ...
    gjp dry-run
    gjp mvn package
    gjp finish
    gjp generate-all

#### Kit sources

If you want to redistribute your RPMs, chances are that you need source files for kit contents.

If you use Maven, most sources for binary jars in your kit can be automatically downloaded:

    gjp get-maven-source-jars

For non-Maven jars, or Maven jars that have no available sources, some extra manual work is needed. First of all, you should get a `pom.xml` file for your jar, if you don't have it already:

    gjp get-pom jarname.jar

This will create a `jarname.pom` file (if it can be found in Maven Central, otherwise you will need to search the Internet manually).

If you are lucky, the pom file will contain an URL to a site where sources can be downloaded, or even an SCM address. At the moment automatic source retrieval is not automated, but `gjp` can help you with the following utility subcommands:

* `gjp get-source-address POM` will attempt to find the SCM Internet address of a pom.xml from the file itself or through api.github.com. `POM` can either be a filename or a URI;
* `gjp get-source POM ADDRESS` downloads the source of a pom.xml's project from its SCM at ADDRESS;

More comprehensive support is planned in future releases.

#### Optional: Ant packages

Building Ant packages is not really different from Maven ones, as `gjp ant` will operate exactly like `gjp mvn`.

Sometimes you will have jar files distributed along with the source archive that will end up in `src/`: you don't want that, just run `gjp purge-jars` to have them moved to the kit. The command will generate a symlink back to the original, so builds will not fail.

Once built, you should get a pom.xml file (via `gjp get-pom`, see above) in order to generate its spec.

#### Optional: running networkless dry-run builds

`gjp` has a subcommand to setup a `nonet` user without Internet access, courtesy of `iptables`. You can simply retry the build using that user to see if it works. Note that the following commands will alter group permissions to allow both your current user and `nonet` to work on the same files.

    gjp set-up-nonet-user
    chmod -R g+rw ../../..
    gjp dry-run
    su nonet
    ping www.google.com #this should fail!
    gjp mvn package
    chmod -R g+rw .
    exit
    gjp finish

The above is not mandatory, but it can be useful for debugging purposes.


### Gotchas

* `gjp` internally uses `git` to keep track of files, any gjp project is actually also a `git` repo. Feel free to navigate it, you can commit, push and pull as long as the `gjp` tags are preserved. You can also delete commits and tags, effectively rewinding gjp history (just make sure to delete all tags pointing to a certain commit when you discard it);
* if your sources come from a Git repo, be sure to remove any `.git`/`.gitignore` files, otherwise `gjp` might get confused;
* if OBS complains that jars in your kit or package are compiled for a JDK version higher than 1.5, add the following line after `%install` to squelch the error:

    export NO_BRP_CHECK_BYTECODE_VERSION=true


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
