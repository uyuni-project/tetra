gjp – Green Java Packager's tools
===

`gjp` (pronounced _/ˈdʒiː ˈaɪ ˈd͡ʒəʊ/_) is a set of tools to ease and partially automate Linux packaging of Java projects.

The project focus is on producing rpm packages for SUSE distributions, but it is general enough to be useful even for other distributions.


## Install

Easiest install is via RubyGems:

    $ gem install gjp

## Usage

Main workflow subcommands:
* `gjp init` inits a new gjp project in the current directory, generating minimal directories and files;
* `gjp gather` starts a new gathering phase, to add files to the packages you want to create. You should place source files in src/<orgId:artifactId:version>, and binary dependency files in kit/;
* `gjp dry-run` starts a new dry-run phase, where you attempt to build your package. Any change to src/ will be reverted after you call `gjp finish`
* `gjp finish` ends the current phase;
* `gjp mvn` locates and runs Maven from any directory in kit/, using options to force repository in kit/m2 and settings in kit/m2/settings.xml. Use during dry runs;
superuser privileges;
* `gjp generate-kit-spec` creates or refreshes a spec file for the kit package. Use when you are finished gathering and dry-running;
* `gjp generate-kit-archive` creates or refreshes an archive file for the kit package. Use when you are finished gathering and dry-running;
* `gjp generate-source-archive NAME` creates or refreshes an archive file for source package NAME. Use when you are finished gathering and dry-running;

Optional workflow subcommands:
* `gjp set-up-nonet-user` sets up a user named `nonet` without Internet access you can use for networkless dry runs. Requires `iptables` and 
* `gjp tear-down-nonet-user` removes a user previously created by gjp;

Other available tools:
* `gjp get-pom NAME` will attempt to find a pom. `NAME` can be a jar file on your disk, a project directory, or simply a `name-version` string. `gjp` will get the pom either from the package itself or through search.maven.org using heuristic searching;
* `gjp get-parent-pom POM` will attempt to download a pom's parent from search.maven.org, where `POM` is a filename or URI;
* `gjp get-source-address POM` will attempt to find the SCM Internet address of a pom.xml from the file itself or through api.github.com. `POM` can either be a filename or a URI;
* `gjp get-source POM ADDRESS` downloads the source of a pom.xml's project from its SCM at ADDRESS;
* `gjp scaffold-jar-table DIRECTORY` looks for jars in the project's DIRECTORY and classifies them as build-time dependencies (b), run-time dependencies (r) or products (p);

## Source

`gjp`'s Git repo is available on GitHub, which can be browsed at:

    https://github.com/SilvioMoioli/gjp

and cloned with:

    git clone git@github.com:SilvioMoioli/gjp.git
