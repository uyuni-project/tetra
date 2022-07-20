# Motivation

The Java developer world has packages (jars, wars, ears...), tools ([Ant](https://ant.apache.org), [Maven](https://maven.apache.org), [Ivy](https://ant.apache.org/ivy), [Gradle](https://www.gradle.org/), ...) and established workflows to handle software distribution while Linux distros have their own ([zypper](https://en.opensuse.org/Portal:Zypper), [yum](https://en.wikipedia.org/wiki/Yum_(software)), [APT](https://en.wikipedia.org/wiki/APT_(software)), ...). Since the two communities have different goals and requirements, Linux distros typically want to repackage Java software with their own format, tools and workflows. Reasons range from ease of installation, predictable rebuildability, support to (security) patching, management tools, legal issues, etc.

Unfortunately those two "schemes" became very different over time, so automatic translation/repackaging is not possible except in very simple cases. This leads to a lot of tedious, error-prone manual work that Linux packagers have to do in order to fit the "alien" Java model into distro packaging rules that were thought and optimized with a different ecosystem in mind.

A typical example is packaging any software built by Maven on SUSE distros. A number of pain points arise:

* Maven requires internet access and downloads precompiled code as part of the build. RPMs have to be built on a standalone machine in [OBS](https://en.opensuse.org/openSUSE:Build_Service), and they should build code from sources they are provided beforehand exclusively;
* [Maven is basically a plugin container](https://maven.apache.org/plugins/), so hundreds of different plugins have to be installed to build real-life projects (the exact plugin set and their dependencies is determined at build time). While this is no big deal for Java developers, since they get the corresponding jars prebuilt from public internet Maven repositories, it is a nightmare for distros, because all shipping code is supposed to be built from scratch and packaged!
* Maven often uses multiple versions of a same library or plugin during the same build. Usually distros do not accept more than one version of any given library to reduce maintenance work;
* Maven requires itself in order to build. To be more exact, Maven needs Nexus, which in turn needs Maven and Nexus. To be more exact, its build dependency graph is a very complicated mess with lots of cycles that have to be broken manually.

## Existing solutions

In the openSUSE community, it is a packager's duty to handle those differences, but this limits the amount of software the community is able to package due to the high effort required to overcome them.

The Fedora community uses another set of tools, [XMvn](https://mizdebsk.fedorapeople.org/xmvn/site/), which goals are similar to `tetra`'s. They are limited to Maven, though.

The Debian community has [various tools](https://wiki.debian.org/Java/Packaging), and among those one that automatically patches `pom.xml` Maven files. The downside is that those files will be different from the original upstream's, so they will have to be kept up to date.

The Arch community [basically ignores the problem](https://wiki.archlinux.org/index.php/Java_Package_Guidelines): "You do not need to compile Java applications from source.".

## Kit rationale

`tetra` simplifies the packaging process mostly because of its use of packaged binary blobs that contain all build time dependencies for a set of packages. This is called a **kit**.

Building software from a binary blob is unusual for Linux distros, and it surely has some drawbacks. It is anyway believed that benefits outweigh them, in fact using prebuilt software:

* drastically reduces packaging efforts. A very basic and relatively simple package like [commons-collections](https://commons.apache.org/proper/commons-collections/) needs about [150 jars](https://build.opensuse.org/package/show/home:SilvioMoioli/myproject-kit) just to be compiled and tested. Those should be packaged, roughly, one-by-one!
* is just the way all Java developers out there build, test and use their software — this is how they expect it to work. Any different approach is necessarily error-prone and could result in unexpected bugs;
* does not affect the ability of providing patches to Java projects, as only build time requirements are in the kit. In virtually all cases patching a piece of software does not require to patch its build toolchain;
* does not affect the ability of complying to software licenses like the GPL. In fact those licenses only require to redistribute a project's source code - not the whole toolchain needed to build it. Sources can be added and shipped together with binaries when licenses require it.
