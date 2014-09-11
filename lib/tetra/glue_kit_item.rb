# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a jar file
  # in a kit
  class GlueKitItem
    # implement to_spec
    include SpecGenerator
    attr_reader :project
    attr_reader :package_name
    attr_reader :spec_dir
    attr_reader :template_spec_name

    attr_reader :provides_symbol
    attr_reader :provides_version
    attr_reader :install_dir

    def initialize(project)
      @project = project
      @package_name = "kit-glue-#{project.name}"
      @spec_dir = "kit"
      @template_spec_name = "kit_item.spec"

      @provides_symbol = "kit-glue(#{project.name})"
      @provides_version = project.version
      @install_dir = ""
    end
  end
end
