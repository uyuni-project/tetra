# encoding: UTF-8

module Tetra
  # represents a Java project packaged in tetra
  class Package
    extend Forwardable
    include Speccable
    include Scriptable

    attr_reader :patches

    def_delegator :@project, :name
    def_delegator :@project, :src_archive
    def_delegator :@kit, :name, :kit_name
    def_delegator :@kit, :version, :kit_version
    def_delegator :@pom, :license_name, :license
    def_delegator :@pom, :url
    def_delegator :@pom, :group_id
    def_delegator :@pom, :version
    def_delegator :@pom, :runtime_dependency_ids

    def initialize(project, pom_path = nil, filter = nil, patches = [])
      @project = project
      @kit = Tetra::KitPackage.new(project)
      @pom = Tetra::Pom.new(pom_path)
      @filter = filter
      @patches = patches.map { |f| File.basename(f) }
    end

    def artifact_ids
      @pom.modules.any? ? @pom.modules : [@pom.artifact_id]
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
      @project.produced_files.select do |file|
        File.fnmatch?(@filter, File.basename(file))
      end
    end

    def cleanup_description(raw, max_length)
      # Normalize spaces and strip and truncate to max_length
      raw = raw.gsub(/[\s]+/, " ").strip
      raw = raw.slice(0..max_length - 1)

      # Remove the last word if it was cut off (preceded by a space)
      raw = raw.sub(/\s\w+\z/, "")

      # Safely remove trailing dots linear in O(N)
      raw = raw[0...-1] while raw.end_with?(".")

      raw
    end

    def to_spec
      _to_spec(@project, name, "package.spec", @project.packages_dir)
    end

    def to_script
      _to_script(@project)
    end
  end
end
