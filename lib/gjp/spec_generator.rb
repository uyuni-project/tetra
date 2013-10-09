# encoding: UTF-8

module Gjp
  # creates and updates spec files
  class SpecGenerator
    include Logger

    def initialize(project)
      @project = project
    end

    def generate_kit_spec
      destination_dir = File.join(@project.full_path, "output", "#{@project.name}-kit")
      FileUtils.mkdir_p(destination_dir)
      spec_path = File.join(destination_dir, "#{@project.name}-kit.spec")
      conflict_count = generate_merging("kit.spec", @project.get_binding, spec_path, :generate_kit_spec)
      [spec_path, conflict_count]
    end

    def generate_package_spec(name, pom, filter)
      destination_dir = File.join(@project.full_path, "output", name)
      FileUtils.mkdir_p(destination_dir)
      spec_path = File.join(destination_dir, "#{name}.spec")

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
