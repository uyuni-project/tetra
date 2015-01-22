# tetra – builds RPMs for Java software

`tetra` is a tool to help you build RPM packages for Java projects.

Packaging of Java projects is sometimes hard - mainly because build tools like Maven partially overlap with distro ones like RPM.

See [MOTIVATION.md](MOTIVATION.md) for further information.

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
* execute `tetra dry-run start`, then any command needed to compile your software, then `tetra dry-run finish`;
* execute `tetra generate-all`: tetra will look at changed files and Bash history to scaffold spec files and tarballs.

Done!

### How can that possibly work?

With `tetra` you are not building all dependencies from source, just your package. Everything else is shipped already compiled with attached source files, which is much easier to implement and automate. Yet, it is sufficient to fulfill open source licenses and to have a repeatable, networkless build.

## A commons-collections walkthrough

First, ceate a new `tetra` project named after the package that we want to build:

    mkdir commons-collections
    cd commons-collections
    tetra init

Second, place source files in the `src/` folder:

    cd src
    wget http://archive.apache.org/dist/commons/collections/source/commons-collections-3.2.1-src.zip
    unzip commons-collections-3.2.1-src.zip
    rm commons-collections-3.2.1-src.zip

Third, you need to show `tetra` how to build your package by running appropriate commands between `tetra dry-run start` and `tetra dry-run finish`. Bash history will be recorded to generate a "starting-point" build script (that will be sufficient in simple cases like this):

    cd ../src
    tetra dry-run start

    cd commons-collections-3.2.1-src/
    tetra mvn package

    tetra dry-run finish

Note that we used `tetra mvn package` instead of `mvn package`: this will use a preloaded Maven bundled in `kit/` by default and the repository in `kit/m2`.
Also note that this being a dry-run build, sources will be brought back to their original state after `tetra finish`, as this ensures build repeatability.

Finally, generate build scripts, spec files and tarballs in the `packages/` directory:

    tetra generate-all

Note that `tetra` will generate files for the commons-collections package and all binary-only build-time dependencies in the `packages/` folder.

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
