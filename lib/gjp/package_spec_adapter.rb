  # encoding: UTF-8

module Gjp
  # encapsulates details of a package needed by the spec file
  # retrieving them from other objects
  class PackageSpecAdapter
    attr_reader :name
    attr_reader :version
    attr_reader :license
    attr_reader :summary
    attr_reader :url
    attr_reader :project_name
    attr_reader :project_version
    attr_reader :group_id
    attr_reader :artifact_id
    attr_reader :version
    attr_reader :runtime_dependency_ids
    attr_reader :description
    attr_reader :outputs

    def initialize(project, package_name, pom, filter)
      @name = package_name
      @version = pom.version
      @license = if pom.license_name != ""
        pom.license_name
      else
        "Apache-2.0"
      end
      @summary = cleanup_description(pom.description, 60)
      @url = pom.url
      @project_name = project.name
      @project_version = project.version
      @group_id = pom.group_id
      @artifact_id = pom.artifact_id
      @version = pom.version
      @runtime_dependency_ids = pom.runtime_dependency_ids
      @description = cleanup_description(pom.description, 1500)

      output_list = File.join(project.full_path, "file_lists", "#{@name}_output")
      @outputs = File.open(output_list).readlines.map do |line|
        line.strip
      end.select do |line|
        File.fnmatch? filter, File.basename(line.strip)
      end
    end

    def get_binding
      binding
    end

    def cleanup_description(raw, max_length)
      raw
        .gsub(/[\s]+/, " ")
        .strip
        .slice(0..max_length -1)
        .sub(/\s\w+$/, "")
        .sub(/\.+$/, "")
    end
  end
end

