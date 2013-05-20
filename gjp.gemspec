# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
require "gjp/version"

Gem::Specification.new do |s|
  s.name = "gjp"
  s.version = Gjp::VERSION
  s.authors = ["Silvio Moioli"]
  s.email = ["smoioli@suse.de"]
  s.homepage = "https://github.com/SilvioMoioli/gjp"
  s.summary = "Green Java Packager's Tools"
  s.description = "A suite of tools to ease Java packaging in SUSE systems"

  s.rubyforge_project = "gjp"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Dependencies
  s.add_runtime_dependency 'clamp'
end
