# Development environment

To develop tetra, you will need:
 * to install Bundler and Ruby development headers. On SUSE distros, use `sudo zypper install ruby2.5-rubygem-bundler ruby2.5-devel`;
 * to get development dependencies: `bundle install`;

To install a development version of tetra use:

```
sudo rake install
```

To run tests, simply run `rake`. Please note that tests are divided into fine (more similar to unit tests) and coarse (more similar to integration tests).
