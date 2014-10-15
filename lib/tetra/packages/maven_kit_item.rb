# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a Maven local repo
  # in a kit
  class MavenKitItem
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

    def initialize(project, pom, source_paths)
      path, _ = path_split(pom)
      rest, version = path_split(path)
      group_directory, artifact_id = path_split(rest)
      group_id = path_to_group(group_directory)

      @project = project
      @package_name = "kit-item-#{group_id.gsub(".", "-")}-#{artifact_id}-#{version}"
      @conflicts = false

      @provides_symbol = "tetra-mvn(#{group_id}:#{artifact_id})"
      @provides_version = version
      @install_dir = "m2"

      @source_dir = File.join("kit", "m2")
      @source_paths = source_paths
    end

    def to_archive
      _to_archive(@project, @package_name, @source_dir, @source_paths)
    end

    def to_spec
      _to_spec(@project, @package_name, "kit", "kit_item.spec")
    end

    private

    # splits a path string into a [head, tail] string couple
    def path_split(path)
      Pathname.new(path).split.map { |e| e.to_s }
    end

    # transforms a path into a Maven group
    def path_to_group(path)
      splits = path_split(path)
      if splits[0] == "."
        return splits[1]
      else
        return "#{path_to_group(splits[0])}.#{splits[1]}"
      end
    end
  end
end
