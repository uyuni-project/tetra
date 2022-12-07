# Contributing

## Development environment

To develop tetra, you will need:

* to install Bundler and Ruby development headers. On SUSE distros, use
  `sudo zypper install ruby2.5-rubygem-bundler ruby-devel`;
* to get development dependencies: `bundle install`;

To install a development version of tetra use:

```bash
sudo rake install
```

To run tests, simply run `rake`. Please note that tests are divided into fine (more similar to unit tests) and coarse
(more similar to integration tests).

## Release

Install gem-release: `gem install gem-release`
Bump a patch version: `gem bump -v patch -p -t -r`
