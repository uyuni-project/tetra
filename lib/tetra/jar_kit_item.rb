# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a jar file
  # in a kit
  class JarKitItem
    # implement to_spec
    include SpecGenerator
    attr_reader :project
    attr_reader :package_name
    attr_reader :spec_dir
    attr_reader :template_spec_name

    # template-specific  attributes
    attr_reader :provides_symbol
    attr_reader :provides_version
    attr_reader :install_dir

    def initialize(project, path)
      _, name = Pathname.new(path).split
      hash = Digest::SHA1.file(path).hexdigest

      @project = project
      @package_name = "kit-item-#{name.to_s.gsub('.','-')}"
      @spec_dir = "kit"
      @template_spec_name = "kit_item.spec"

      @provides_symbol = "jar(#{name})"
      @provides_version = hash
      @install_dir = "jars"
    end
  end
end
