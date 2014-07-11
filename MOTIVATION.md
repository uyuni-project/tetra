# Motivation

The Java developer world has packages (jars, wars, ears...), tools ([ant](http://ant.apache.org/), [Maven](http://maven.apache.org/), [Ivy](http://ant.apache.org/ivy/), [Gradle](http://www.gradle.org/)...) and established workflows to handle software distribution while Linux distros have their own ([zypper](http://en.opensuse.org/Portal:Zypper), [yum](http://en.wikipedia.org/wiki/Yellowdog_Updater,_Modified), [apt](http://en.wikipedia.org/wiki/Advanced_Packaging_Tool)...). Since the two communities have different goals and requirements, Linux distros typically want to repackage Java software with their own format, tools and workflows. Reasons range from ease of installation, predictable rebuildability, support to (security) patching, management tools, legal issues, etc.

Unfortunately those two "schemes" became very different over time, so automatic translation/repackaging is not possible except in very simple cases. This leads to a lot of tedious, error-prone manual work that Linux packagers have to do in order to fit the "alien" Java model into distro packaging rules that were thought and optimized with a different ecosystem in mind.

A typical example is packaging any software built by Maven on SUSE distros. A number of pain points arise:

* Maven requires Internet access and downloads precompiled code as part of the build. RPMs have to be built on a standalone machine in [OBS](http://en.opensuse.org/openSUSE:Build_Service), and they should build code from sources they are provided beforehands exclusively;
* [Maven is basically a plugin container](http://maven.apache.org/plugins/), so hundreds of different plugins have to be installed to build real-life projects (the exact plugin set and their dependencies is determined at build time). While this is no big deal for Java developers, since they get the corresponding jars prebuilt from public Intenet Maven repositories, it is a nightmare for distros, because all shipping code is supposed to be built from scratch and packaged!
* Maven often uses multiple versions of a same library or plugin during the same build. Usually distros do not accept more than one version of any given library to reduce maintenance work;
* Maven requires itself in order to build. To be more exact, Maven needs Nexus, which in turn needs Maven and Nexus. To be more exact, its build dependency graph is a very complicated mess with lots of cycles that have to be broken manually.

The current solution in openSUSE is having the packager handle those differences, but this limits the amount of software the community is able to package due to the high effort required to overcome them.

The Fedora community is experimenting with another set of tools, [XMvn](http://mizdebsk.fedorapeople.org/xmvn/site/), which goals are similar to `tetra`'s. 

## Kit rationale

`tetra` simplifies the packaging process mostly because of its use of a binary blob package that contains all build time dependencies for a set of packages called a **kit**.

Building software from a binary blob is unusual for Linux distros, and it surely has some drawbacks. It is anyway believed that benefits outweigh them, in fact using prebuilt software:

* drastically reduces packaging efforts. A very basic and relatively simple package like [commons-collections](http://commons.apache.org/proper/commons-collections/) needs about [150 jars](https://build.opensuse.org/package/show/home:SilvioMoioli/myproject-kit) just to be compiled and tested. Those should be packaged, roughly, one-by-one!
* is just the way all Java developers out there build, test and use their software — this is how they expect it to work. Any different approach is necessarily error-prone and could result in unexpected bugs;
* does not affect the ability of providing patches to Java projects, as only build time requirements are in the kit. In virtually all cases patching a piece of software does not require to patch its build toolchain;
* does not affect the ability of complying to software licenses like the GPL. In fact those licenses only require to redistribute a project's source code - not the whole toolchain needed to build it. Sources can be added and shipped together with binaries when licenses require it.
