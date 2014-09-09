# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a Maven local repo
  # in a kit
  class MavenKitItem
    extend Forwardable

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

    # other attributes
    attr_reader :files

    def initialize(project, pom, files)
      path, _ = path_split(pom)
      rest, version = path_split(path)
      group_directory, artifact_id = path_split(rest)
      group_id = path_to_group(group_directory)

      @project = project
      @package_name = "kit-item-#{group_id.gsub(".", "-")}-#{artifact_id}-#{version}"
      @spec_dir = "kit"
      @template_spec_name = "kit_item.spec"

      @provides_symbol = "mvn(#{group_id}:#{artifact_id})"
      @provides_version = version
      @install_dir = "m2"

      @files = files
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
