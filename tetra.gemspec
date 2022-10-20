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

  s.add_development_dependency "aruba", "~> 0.6.2"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rubocop", "~> 1.37.0"

  s.add_runtime_dependency "clamp"
  s.add_runtime_dependency "erb", "~> 2.2.3"
  s.add_runtime_dependency "json_pure"
  s.add_runtime_dependency "open4"
  s.add_runtime_dependency "rexml"
  s.add_runtime_dependency "rubyzip", ">= 1.0"
  s.add_runtime_dependency "text"
end
