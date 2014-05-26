# encoding: UTF-8

module Gjp
  # creates and updates spec files
  class SpecGenerator
    include Logging

    def initialize(project)
      @project = project
    end

    def generate_kit_spec
      @project.from_directory do
        spec_name = "#{@project.name}-kit.spec"
        spec_path = File.join("kit", spec_name)
        output_dir = File.join("output", "#{@project.name}-kit")
        FileUtils.mkdir_p(output_dir)

        adapter = Gjp::KitSpecAdapter.new(@project)
        conflict_count = generate_merging("kit.spec", adapter.public_binding, spec_path, :generate_kit_spec)

        symlink_to_output(spec_path, output_dir)

        [spec_path, conflict_count]
      end
    end

    def generate_package_spec(name, pom_path, filter)
      pom = Gjp::Pom.new(pom_path)
      @project.from_directory do
        spec_name = "#{name}.spec"
        spec_path = File.join("src", name, spec_name)
        output_dir = File.join("output", name)
        FileUtils.mkdir_p(output_dir)

        adapter = Gjp::PackageSpecAdapter.new(@project, name, pom, filter)
        conflict_count = generate_merging("package.spec", adapter.public_binding, spec_path, "generate_#{name}_spec")

        symlink_to_output(spec_path, output_dir)

        [spec_path, conflict_count]
      end
    end

    private

    # generates a spec file from a template and 3-way merges it
    def generate_merging(template, binding, path, tag_prefix)
      new_content = TemplateManager.new.generate(template, binding)
      @project.merge_new_content(new_content, path, "Spec generated", tag_prefix)      
    end

    # links a spec file in a subdirectory of output/
    def symlink_to_output(spec_path, destination_dir)
      spec_name = Pathname.new(spec_path).basename.to_s
      destination_spec_path = File.join(destination_dir, spec_name)
      FileUtils.symlink(File.expand_path(spec_path), destination_spec_path, force: true)
    end
  end
end
