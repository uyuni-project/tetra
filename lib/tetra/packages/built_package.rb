# encoding: UTF-8

module Tetra
  # represents a Java project packaged in tetra
  class BuiltPackage
    extend Forwardable
    include Archivable
    include Speccable
    include Scriptable

    def_delegator :@project, :name, :name
    def_delegator :@kit, :name, :kit_name
    def_delegator :@kit, :version, :kit_version
    def_delegator :@pom, :license_name, :license
    def_delegator :@pom, :url
    def_delegator :@pom, :group_id
    def_delegator :@pom, :artifact_id
    def_delegator :@pom, :version
    def_delegator :@pom, :runtime_dependency_ids

    def initialize(project, pom_path = nil, filter = nil)
      @project = project
      @kit = Tetra::Kit.new(project)
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
      @project.produced_files.select do |file|
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

    def to_archive
      _to_archive(@project, name, "src", @project.packages_dir)
    end

    def to_spec
      _to_spec(@project, name, "package.spec", @project.packages_dir)
    end

    def to_script(history)
      _to_script(@project, history)
    end
  end
end
