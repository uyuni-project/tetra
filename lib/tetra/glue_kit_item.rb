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

    # implement to_archive
    include Archiver
    attr_reader :source_dir
    attr_reader :source_paths
    attr_reader :destination_dir

    # template-specific attributes
    attr_reader :provides_symbol
    attr_reader :provides_version
    attr_reader :install_dir

    def initialize(project, source_paths)
      @project = project
      @package_name = "kit-item-glue-#{project.name}"
      @spec_dir = "kit"
      @template_spec_name = "kit_item.spec"

      @source_dir = File.join("kit")
      @source_paths = source_paths
      @destination_dir = @package_name

      @provides_symbol = "tetra-glue(#{project.name})"
      @provides_version = project.version
      @install_dir = ""
    end
  end
end
