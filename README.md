[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/6678/badge)](https://www.bestpractices.dev/projects/6678)
[![Tests](https://github.com/uyuni-project/tetra/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/uyuni-project/tetra/actions/workflows/test.yml)
[![codecov](https://codecov.io/github/uyuni-project/tetra/branch/master/graph/badge.svg?token=iLBGZqGXwa)](https://codecov.io/github/uyuni-project/tetra)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=uyuni-project_tetra&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=uyuni-project_tetra)

# tetra – builds RPMs for Java software

`tetra` is a tool to help you build RPM packages for Java projects.

Packaging of Java projects is sometimes hard - mainly because build tools like Maven partially overlap with distro ones
like RPM.

See [MOTIVATION.md](MOTIVATION.md) for further information.

## Prerequisites

- [Ruby 3.4](https://www.ruby-lang.org) or later;
- [git](https://git-scm.com) with your credentials set in `~/.gitconfig` (name and email);
- some basic Unix commands: `bash`, `unzip`, `tar`;
- a JDK > 8 that can compile whatever software you need to package;
- Fedora only: packages to compile native gems, use `yum install ruby-devel gcc-c++ zlib-devel`;

## Installation

You can install `tetra` via RubyGems or by building and installing it yourself.

```bash
# via RubyGems (currently version 2.0.6 from 02/2020)
gem install tetra

# from source
rake install
```

## Tests

Test can be found in the `spec/` folder and are divided into fine (more similar to unit tests) and coarse
(more similar to integration tests).
To run tests manually, simply execute `rake`.
With every Pull Request against master and consecutive pushes to that PR, several [GitHub Actions tests](https://github.com/uyuni-project/tetra/tree/master/.github/workflows)
will run automatically.

## Workflow

Building a package with `tetra` is quite unusual — this is a deliberate choice, so don't worry. Basic steps are:

- `tetra init <package name> package_sources.tar.gz` to initialize the project and unpack original sources;
- `cd` into the newly created `<package name>` directory
- if anything other than `ant` and `mvn` is needed in order to build the project, add it to the `kit/` directory in
  binary form;
- execute `tetra dry-run`, which will open a bash subshell. Build your project, and when you are done conclude by
  exiting the subshell with `Ctrl+D`;
- `cd` into the directory that contains `pom.xml` and execute `tetra generate-all`: tetra will scaffold spec files and
  tarballs.

Done!

### How can that possibly work?

During the dry-run `tetra`:

- saves your bash history, so that it can use it later to scaffold a build script;
- keeps track of changed files, in particular produced jars, which are included in the spec's `%files` section;
- saves files downloaded from the Internet (eg. by Maven) and packs them to later allow networkless builds.

Note that with `tetra` you are not building all dependencies from source - build dependencies are aggregated in a
binary-only "kit" package. This is typically sufficient to fulfill open source licenses and to have a repeatable,
networkless build.

## A commons-collections walkthrough

First, grab the sources:

```bash
wget https://archive.apache.org/dist/commons/collections/source/commons-collections4-4.5.0-M2-src.tar.gz
```

Second, create a new `tetra` project named `commons-collections` based on those sources:

```bash
tetra init commons-collections commons-collections4-4.5.0-M2-src.tar.gz
cd commons-collections/src/commons-collections4-4.5.0-M2-src
```

Third, you need to show `tetra` how to build your package. Run `tetra dry-run` and a new subshell will open, in there do
anything you would normally do to build the package (in this case, run Maven):

```bash
tetra dry-run
mvn package
^D
```

Note that you don't even need to install Maven - `tetra` bundles a copy in `kit/` and uses it by default!
Also note that this being a dry-run build, sources will be brought back to their original state after it finishes to
ensure repeatability.

Finally, generate build scripts, spec files and tarballs in the `packages/` directory:

```bash
tetra generate-all
```

Note that `tetra` will generate files for the commons-collections package and all binary-only build-time dependencies in
the `packages/` folder.

## In-depth information

In more complex cases building a package will require some special tweaks. We are trying to cover the most common in the
[SPECIAL_CASES.md](SPECIAL_CASES.md) file.

An in-depth discussion of this project's motivation is available in the [MOTIVATION.md](MOTIVATION.md) file.

## Status

`tetra` is considered stable. At the moment `tetra` is tested on openSUSE and on Ubuntu with GitHub Actions.

# Security

Please see [SECURITY.md](SECURITY.md) for more information.

## Sources

`tetra`'s Git repo is available on [GitHub](https://github.com/uyuni-project/tetra).

## License

MIT license.
