# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a jar file
  # in a kit
  class GlueKitItem
    include Archiver
    include SpecGenerator

    attr_reader :project
    attr_reader :package_name
    attr_reader :conflicts
    attr_reader :source_dir
    attr_reader :source_paths
    attr_reader :provides_symbol
    attr_reader :provides_version
    attr_reader :install_dir

    def initialize(project, source_paths)
      @project = project
      @package_name = "kit-item-glue-#{project.name}"
      @conflicts = true
      @source_dir = "kit"
      @source_paths = source_paths

      @provides_symbol = "tetra-glue"
      @provides_version = "#{project.name}-#{project.version}"
      @install_dir = ""
    end

    def to_archive
      _to_archive(@project, @package_name, @source_dir, @source_paths)
    end

    def to_spec
      _to_spec(@project, @package_name, "kit", "kit_item.spec")
    end
  end
end
