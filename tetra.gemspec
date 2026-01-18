# frozen_string_literal: true

require_relative "lib/tetra/version"

Gem::Specification.new do |spec|
  spec.name        = "tetra"
  spec.version     = Tetra::VERSION
  spec.authors     = ["Dominik Gedon", "Silvio Moioli"]
  spec.email       = ["dominik.gedon@suse.com", "silvio.moioli@suse.com"]
  spec.homepage    = "https://github.com/uyuni-project/tetra"
  spec.summary     = "A tool to package Java projects"
  spec.description = <<~TEXT
    Tetra simplifies the creation of spec files and archives
    to distribute Java projects in RPM format.
  TEXT

  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/uyuni-project/tetra/issues",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/uyuni-project/tetra",
    "rubygems_mfa_required" => "true",
    "allowed_push_host" => "https://rubygems.org"
  }

  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir.glob(
    [
      "bin/*",
      "lib/**/*",
      "*.md",
      "LICENSE",
      "COPYING"
    ]
  ).select { |f| File.file?(f) }

  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.rdoc_options << "--exclude=lib/template/bundled"

  # Dependencies
  spec.add_runtime_dependency "clamp", "~> 1.3"
  spec.add_runtime_dependency "json_pure", ">= 2.6.3", "< 2.9.0"
  spec.add_runtime_dependency "rexml", ">= 3.2.9", "< 3.5.0"
  spec.add_runtime_dependency "rubyzip", "~> 3.2"
  spec.add_runtime_dependency "text", "~> 1.3"

  spec.add_development_dependency "aruba", "~> 2.3"
  spec.add_development_dependency "rake", "~> 13.3"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.82"
  spec.add_development_dependency "rubocop-performance", "~> 1.26"
  spec.add_development_dependency "rubocop-rake", "~> 0.7"
  spec.add_development_dependency "rubocop-rspec", "~> 3.9.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-cobertura", "~> 3.1"
end
