# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a Maven local repo
  # in a kit
  class MavenKitItem
    extend Forwardable
    include SpecGenerator

    def_delegator :@project, :name, :project_name

    attr_reader :provides_symbol
    attr_reader :provides_version
    attr_reader :files

    def initialize(pom, files)
      @files = files

      path, _ = Pathname.new(pom).split
      rest, version = path.split
      group_directory, artifact_id = rest.split
      group_id = path_to_group(group_directory)

      @provides_symbol = "mvn(#{group_id}:#{artifact_id})"
      @provides_version = version.to_s
    end

    private

    def path_to_group(path)
      splits = path.split
      if splits[0].to_s == "."
        return splits[1]
      else
        return "#{path_to_group(splits[0])}.#{splits[1]}"
      end
    end
  end
end
