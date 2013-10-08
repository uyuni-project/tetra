# encoding: UTF-8

module Gjp
  # creates and updates spec files
  class SpecGenerator
    include Logger

    def initialize(project)
      @project = project
    end

    def generate_kit_spec
      spec_path = File.join("specs", "#{@project.name}-kit.spec")
      conflict_count = generate_merging("kit.spec", @project.get_binding, spec_path, :generate_kit_spec)
      [spec_path, conflict_count]
    end

    def generate_package_spec(name, pom, filter)
      spec_path = File.join("specs", "#{name}.spec")

      list_file = File.join(@project.full_path, "file_lists/#{name}_output")
      if not File.exist? list_file
        return nil
      end

      adapter = Gjp::PackageSpecAdapter.new(@project, name, Gjp::Pom.new(pom), filter)

      conflict_count = generate_merging("package.spec", adapter.get_binding, spec_path, "generate_#{name}_spec")
      [spec_path, conflict_count]
    end

    # generates a spec file from a template and 3-way merges it
    def generate_merging(template, binding, path, tag_prefix)
      new_content = TemplateManager.new.generate(template, binding)
      @project.merge_new_content(new_content, path, "Spec generated", tag_prefix)      
    end
  end
end
