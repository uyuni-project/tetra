# gjp – helps you build RPMs for Java software

`gjp` is a set of tools to help you build RPM packages for Java projects.

Packaging of Java projects is sometimes hard because build tools like Maven partially overlap with distro tools like RPM in functionality.

We are trying to come up with **a tool that drastically simplifies packaging**, and that is `gjp`.

## Installation

You need:

* [Ruby 1.9](https://www.ruby-lang.org/en/);
* [git](http://git-scm.com/);
* a JDK that can compile whatever software you need to package;

Install `gjp` via RubyGems:

     gem install gjp

## Workflow

Building a package with `gjp` is quite unusual — this is a deliberate choice, so don't worry. Basic steps are:

* `gjp init` a new project;
* add sources to `src/<package name>` and anything else needed for the build in `kit/` in binary form (typically a copy of Maven and maybe some other dependency jars);
* execute `gjp dry-run`, then any command needed to compile your software, then `gjp finish`;
* execute `gjp generate-all`: gjp will look at changed files and Bash history to scaffold spec files and tarballs. You should already have working RPMs at this point;
* execute `gjp download-maven-source-jars` or [some other command](#kit-sources) to add sources of binary dependency in `kit/`, if required by licenses.

Done!

### How can that possibly work?

With `gjp` you are not building all dependencies from source, just your package. Everything else is shipped already compiled with attached source files, which is much easier to implement and automate yet is enough to fulfill open source licenses and to have a repeatable, networkless build. See [MOTIVATION.md](MOTIVATION.md) for further information.

## A commons-collections walkthrough

First, ceate a new `gjp` project, in this example named "myproject":

    mkdir myproject
    cd myproject
    gjp init

Second, place commons-collections source files in the `src/` folder. Specifically, every `src/` subfolder will become a separate package named after the folder itself, so you can use the following:

    cd src
    mkdir commons-collections
    cd commons-collections
    wget http://archive.apache.org/dist/commons/collections/source/commons-collections-3.2.1-src.zip
    unzip commons-collections-3.2.1-src.zip
    rm commons-collections-3.2.1-src.zip

Third, put all non-source files needed for the build in `kit/`. This means all build dependencies and tools excluding the JDK: in this case it is just Maven:

    cd ../../kit
    wget http://www.eu.apache.org/dist/maven/binaries/apache-maven-3.1.1-bin.zip
    unzip apache-maven-3.1.1-bin.zip
    rm apache-maven-3.1.1-bin.zip

Fourth, you need to show `gjp` how to build your package by running appropriate commands between `gjp dry-run` and `gjp finish`. Bash history will be recorded to generate a "starting-point" build script (that will be sufficient in simple cases like this):

    gjp dry-run
    cd src/commons-collections/commons-collections-3.2.1-src/
    gjp mvn package
    gjp finish

Note that we used `gjp mvn package` instead of `mvn package`: this will use of the Maven copy we put in `kit/` and the repository in `kit/m2`.
Also note that this being a dry-run build, sources will be brought back to their original state after `gjp finish`, as this ensures build repeatability.

Finally, generate build scripts, spec files and tarballs:

    gjp generate-all

Note that `gjp` will also generate a special binary-only package called a **kit**, which contains basically the `kit/` folder. This is the only build-time requirement of any `gjp` package in your project.

## In-depth information

In more complex cases building a package will require some special tweaks. We are trying to cover the most common in the [SPECIAL_CASES.md](SPECIAL_CASES.md) file.

An in-depth discussion of this project's motivation is available in the [MOTIVATION.md](MOTIVATION.md) file.

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
