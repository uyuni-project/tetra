# encoding: UTF-8

module Tetra
  # represents a Java project package in Tetra, corresponding to a directory
  # in src/
  class Package
    extend Forwardable

    attr_reader :name

    def_delegator :@project, :name, :project_name
    def_delegator :@project, :version, :project_version

    def_delegator :@pom, :license_name, :license
    def_delegator :@pom, :url
    def_delegator :@pom, :group_id
    def_delegator :@pom, :artifact_id
    def_delegator :@pom, :version
    def_delegator :@pom, :runtime_dependency_ids

    def initialize(project, name, pom_path, filter)
      @project = project
      @name = name
      @pom = Tetra::Pom.new(pom_path)
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

    def generate_spec
      @project.from_directory do
        spec_name = "#{@name}.spec"
        spec_path = File.join("src", name, spec_name)
        output_dir = File.join("output", name)
        FileUtils.mkdir_p(output_dir)

        new_content = TemplateManager.new.generate("package.spec", binding)
        conflict_count = @project.merge_new_content(new_content, spec_path, "Spec generated", "generate_#{name}_spec")

        destination_spec_path = File.join(output_dir, spec_name)
        FileUtils.symlink(File.expand_path(spec_path), destination_spec_path, force: true)

        [spec_path, conflict_count]
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
  end
end
