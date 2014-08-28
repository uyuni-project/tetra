# encoding: UTF-8

module Tetra
  # represents a Java project package in Tetra, corresponding to a directory
  # in src/
  class Package
    extend Forwardable
    include SpecGenerator
    include Archiver

    attr_reader :name

    def_delegator :@project, :name, :project_name
    def_delegator :@project, :version, :project_version

    def_delegator :@pom, :license_name, :license
    def_delegator :@pom, :url
    def_delegator :@pom, :group_id
    def_delegator :@pom, :artifact_id
    def_delegator :@pom, :version
    def_delegator :@pom, :runtime_dependency_ids

    def initialize(project, name, pom_path = nil, filter = nil)
      @project = project
      @name = name
      @pom = pom_path.nil? ? nil : Tetra::Pom.new(pom_path)
      @filter = filter
    end

    # a short summary from the POM
    def summary
      cleanup_description(@pom.description, 60)
    end

    # a long summary from the POM
    def description
      cleanup_description(@pom.description, 1500)
    end

    # files produced by this package
    def outputs
      @project.get_produced_files(@name).select do |file|
        File.fnmatch?(@filter, File.basename(file))
      end
    end

    def cleanup_description(raw, max_length)
      raw
        .gsub(/[\s]+/, " ")
        .strip
        .slice(0..max_length - 1)
        .sub(/\s\w+$/, "")
        .sub(/\.+$/, "")
    end

    # needed by SpecGenerator
    attr_reader :project

    def package_name
      name
    end

    def spec_path
      File.join("src", name, package_name)
    end

    def template_spec_name
      "package.spec"
    end

    def spec_tag
      name
    end

    # needed by Archiver
    def archive_source_dir
      File.join("src", name)
    end

    def archive_destination_dir
      name
    end
  end
end
