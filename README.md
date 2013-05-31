gjp – Green Java Packager's tools
===

`gjp` (pronounced _/ˈdʒiː ˈaɪ ˈd͡ʒəʊ/_) is a set of tools to ease and partially automate Linux packaging of Java projects.

The project focus is on producing rpm packages for SUSE distributions, but it is general enough to be useful even for other distributions.


## Install

Easiest install is via RubyGems:

    $ gem install gjp

## Usage

Currently available tools:
* `gjp get-pom JAR` will attempt to find an jar's pom.xml (either from the package itself or through search.maven.org);
* `gjp get-source-address POM` will attempt to find the SCM Internet address of a pom.xml (from the file itself or through api.github.com);
* `gjp get-source POM ADDRESS` downloads the source of a pom.xml's project from its SCM at ADDRESS;

## Source

`gjp`'s Git repo is available on GitHub, which can be browsed at:

    https://github.com/SilvioMoioli/gjp

and cloned with:

    git clone git@github.com:SilvioMoioli/gjp.git
