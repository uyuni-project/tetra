# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a jar file
  # in a kit
  class JarKitItem
    include Archivable
    include Speccable

    attr_reader :project
    attr_reader :package_name
    attr_reader :conflicts
    attr_reader :source_dir
    attr_reader :source_paths
    attr_reader :provides_symbol
    attr_reader :provides_version
    attr_reader :install_dir

    def initialize(project, path)
      _, name = Pathname.new(path).split
      hash = Digest::SHA1.file(path).hexdigest

      @project = project
      @package_name = "kit-item-#{name.to_s.gsub(".", "-")}"
      @conflicts = false
      @source_dir = File.join("kit", "jars")
      @source_paths = [path]
      @provides_symbol = "tetra-jar(#{name})"
      @provides_version = hash
      @install_dir = "jars"
    end

    def to_archive
      _to_archive(@project, @package_name, @source_dir,
                  @source_paths, @project.kit_packages_dir)
    end

    def to_spec
      _to_spec(@project, @package_name, "kit_item.spec",
               @project.kit_packages_dir)
    end
  end
end
