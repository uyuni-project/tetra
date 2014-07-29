# encoding: UTF-8

module Tetra
  # represents a package of binary dependencies
  class Kit
    extend Forwardable

    def_delegator :@project, :name
    def_delegator :@project, :version

    def initialize(project)
      @project = project
    end

    def generate_spec
      @project.from_directory do
        spec_name = "#{@project.name}-kit.spec"
        spec_path = File.join("kit", spec_name)
        output_dir = File.join("output", "#{@project.name}-kit")
        FileUtils.mkdir_p(output_dir)

        new_content = TemplateManager.new.generate("kit.spec", binding)
        conflict_count = @project.merge_new_content(new_content, spec_path, "Kit spec generated", :generate_kit_spec)

        destination_spec_path = File.join(output_dir, spec_name)
        FileUtils.symlink(File.expand_path(spec_path), destination_spec_path, force: true)

        [spec_path, conflict_count]
      end
    end
  end
end
