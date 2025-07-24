$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "tetra/version"

Gem::Specification.new do |s|
  s.name        = "tetra"
  s.version     = Tetra::VERSION
  s.authors     = ["Dominik Gedon", "Silvio Moioli"]
  s.email       = "dgedon@suse.de"
  s.homepage    = "https://github.com/uyuni-project/tetra"
  s.summary     = "A tool to package Java projects"
  s.description = <<-TEXT
    Tetra simplifies the creation of spec files and archives
    to distribute Java projects in RPM format
  TEXT
  s.license     = "MIT"
  s.metadata    = {
    "bug_tracker_uri" => "https://github.com/uyuni-project/tetra/issues",
    "homepage_uri" => s.homepage,
    "source_code_uri" => "https://github.com/uyuni-project/tetra"
  }

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 3.1.0'

  s.add_development_dependency "aruba", "~> 0.6.2"
  s.add_development_dependency "simplecov", "~> 0.22.0"
  s.add_development_dependency "rake", "~> 13.3.0"
  s.add_development_dependency "rspec", "~> 3.13.0"
  s.add_development_dependency "rubocop", "~> 1.79.0"
  s.add_development_dependency "rubocop-rake", "~> 0.7.1"
  s.add_development_dependency "rubocop-rspec", "~> 3.6.0"

  s.add_runtime_dependency "clamp", "~> 1.3.2"
  s.add_runtime_dependency "erb", "~> 4.0.3"
  s.add_runtime_dependency "json_pure", ">= 2.6.3", "< 2.9.0"
  s.add_runtime_dependency "open4", "~> 1.3.4"
  s.add_runtime_dependency "rexml", ">= 3.2.9", "< 3.5.0"
  s.add_runtime_dependency "rubyzip", ">= 2.3.2", "< 2.5.0"
  s.add_runtime_dependency "text", "~> 1.3.1"
end
