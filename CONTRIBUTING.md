# Development environment

To develop tetra, you will need:
 * to install Bundler. On SUSE distros, use `sudo zypper in rubygem-bundler`;
 * to get development dependencies: `bundle install`;

To install a development version of tetra use:

```
sudo rake install
```

To run tests, simply run `rake`. Please note that tests are divided into fine (more similar to unit tests) and coarse (more similar to integration tests).
