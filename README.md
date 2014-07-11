# tetra – builds RPMs for Java software

`tetra` is a set of tools to help you build RPM packages for Java projects.

Packaging of Java projects is sometimes hard because build tools like Maven partially overlap with distro tools like RPM in functionality.

This tool's goal is to drastically simplifies packaging.

## Installation

You need:

* [Ruby 1.9](https://www.ruby-lang.org/en/);
* [git](http://git-scm.com/);
* a JDK that can compile whatever software you need to package;

Install `tetra` via RubyGems:

     gem install tetra

## Workflow

Building a package with `tetra` is quite unusual — this is a deliberate choice, so don't worry. Basic steps are:

* `tetra init` a new project;
* add sources to `src/<package name>` and anything else needed for the build in `kit/` in binary form (typically a copy of Maven and maybe some other dependency jars);
* execute `tetra dry-run`, then any command needed to compile your software, then `tetra finish`;
* execute `tetra generate-all`: tetra will look at changed files and Bash history to scaffold spec files and tarballs.

Done!

### How can that possibly work?

With `tetra` you are not building all dependencies from source, just your package. Everything else is shipped already compiled with attached source files, which is much easier to implement and automate. Yet, it is sufficient to fulfill open source licenses and to have a repeatable, networkless build. See [MOTIVATION.md](MOTIVATION.md) for further information.

## A commons-collections walkthrough

First, ceate a new `tetra` project, in this example named "myproject":

    mkdir myproject
    cd myproject
    tetra init

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

Fourth, you need to show `tetra` how to build your package by running appropriate commands between `tetra dry-run` and `tetra finish`. Bash history will be recorded to generate a "starting-point" build script (that will be sufficient in simple cases like this):

    cd ../src/commons-collections/commons-collections-3.2.1-src/
    tetra dry-run
    tetra mvn package
    tetra finish

Note that we used `tetra mvn package` instead of `mvn package`: this will use of the Maven copy we put in `kit/` and the repository in `kit/m2`.
Also note that this being a dry-run build, sources will be brought back to their original state after `tetra finish`, as this ensures build repeatability.

Finally, generate build scripts, spec files and tarballs in the `output/` directory:

    tetra generate-all

Note that `tetra` will generate files for the commons-collections package and for the binary-only myproject-kit package, which is a special container of all build-time dependencies (basically, the `kit/` folder). This will be shared among all packages you might add to your `tetra` project.

## In-depth information

In more complex cases building a package will require some special tweaks. We are trying to cover the most common in the [SPECIAL_CASES.md](SPECIAL_CASES.md) file.

An in-depth discussion of this project's motivation is available in the [MOTIVATION.md](MOTIVATION.md) file.

## Status

`tetra` is a research project currently in beta state. If you are a packager you can try to use it, any feedback would be **very** welcome!

At the moment `tetra` is tested on openSUSE.

## Sources

`tetra`'s Git repo is available on GitHub, which can be browsed at:

    https://github.com/SilvioMoioli/tetra

and cloned with:

    git clone git@github.com:SilvioMoioli/tetra.git

## Contact

Are you using `tetra` or even just reading this? Let's get in touch!

    smoioli at suse dot de

## License

MIT license.
