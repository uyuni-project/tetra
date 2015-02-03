# Special cases

## Failing builds

If your build fails for whatever reason, abort it with `tetra finish abort`. `tetra` will restore all project files as they were before build.

## Manual changes to generated files

You can do any manual changes to spec and build.sh files and regenerate them later, `tetra` will reconcile changes with a [three-way merge](http://en.wikipedia.org/wiki/Three-way_merge#Three-way_merge) and alert about any conflicts. You can generate single files with the following commands:

* `tetra generate-script`: (re)generates the `build.sh` file from the latest bash history (assumes `tetra dry-run start` and `tetra dry-run finish` have been used);
* `tetra generate-archive`: (re)generates the package tarball;
* `tetra generate-spec`: (re)generates the package spec;
* `tetra generate-kit`: (re)generates the kit tarball and spec;

## Ant builds

`tetra` is currently optimized for Maven as it is the most common build tool, but it can work with any other. In particular, support for Ant has already been implemented and `tetra ant` works like `tetra mvn`, and a copy of ant is also bundled in `kit/` by default.

Sometimes you will have jar files distributed along with the source archive that will end up in `src/`: you don't want that! Run

    tetra move-jars-to-kit

to have them moved to `kit/jars`. The command will generate a symlink back to the original, so builds will work as expected.

When generating spec files, be sure to have a `pom.xml` in your package directory even if you are not using Maven: `tetra` will automatically take advantage of information from it to compile many fields.

You can also ask `tetra` to find one via `tetra get-pom <filename>.jar` (be sure to have Maven in your kit).

## Other build tools

Other build tools are currently unsupported but will be added in the future. You can nevertheless use them - the only rule is that you have to keep all of their files in `kit`.

## [OBS](build.opensuse.org) integration

If you want to submit your package to OBS, you can do so by copying contents of the `packages` in a proper OBS project directory.

Packages will rebuild cleanly in OBS because no Internet access is needed - all files were already downloaded during dry-run and are included in the kit.

Note that the kit packages is only needed at build time by OBS, no end user should ever install it, so you can place it in a non-public project/repository if you so wish.

## Gotchas

* `tetra` internally uses `git` to keep track of files, any tetra project is actually also a `git` repo. Feel free to use it as any ordinary git repo, including pushing to a remote repo, rebasing, merging or using GitHub's pull requests. Just make sure any `tetra: ` comments are preserved;
* some Maven plugins like the Eclipse Project ones ([Tycho](https://www.eclipse.org/tycho/)) will save data in `/tmp` downloaded from the Internet and will produce errors if this data is not there during offline builds. One way to work around that is to force Java to use a kit subdirectory as `/tmp`. Add the following option to `tetra mvn` during your build:

    -Djava.io.tmpdir=<full path to project>/kit/tmp

Use the following option in `mvn` in your build.sh file to make it reproducible:

    -Djava.io.tmpdir=$PROJECT_PREFIX/kit/tmp

* Tycho builds may also require NSS, so if you get NSS errors be sure to add `mozilla-nss` or an equivalent package in a BuildRequires: line;
* some badly designed testsuites might not work in OBS. If you are using `tetra mvn` you can add the following option to disable them:

   -DskipTests=true

* if you want to be 100% sure your package builds without network access, you can use scripts in the `utils/` folder to create a special `nonet` user that cannot use the Internet and retry the build from that user.
