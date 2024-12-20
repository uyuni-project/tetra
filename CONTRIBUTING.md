# Contributing

## Development environment

To develop tetra, you will need:

* to install Bundler and Ruby development headers. On SUSE distros, use
  `sudo zypper install ruby3.1-rubygem-bundler ruby-devel`;
* to get development dependencies: `bundle install`;

To install a development version of tetra use:

```bash
sudo rake install
```

To run tests, simply run `rake`. Please note that tests are divided into fine (more similar to unit tests) and coarse
(more similar to integration tests).

## Coding style

We use RuboCop to enforce a certain coding style for Ruby. With every Pull request and push, RuboCop checks the coding
style and reports any errors.

## New features

In case you want to add new features, please be aware to also add the necessary fine grained or coarse grained tests
for it.

## Release

Install gem-release: `gem install gem-release`
Bump a patch version: `gem bump -v patch -p -t -r`
