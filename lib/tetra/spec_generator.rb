# encoding: UTF-8

module Tetra
  # implements a to_spec method
  module SpecGenerator
    # expected attributes:
    #   project (Tetra::Project)
    #   package_name (string)
    #   spec_path (string)
    #   template_spec_name (string)
    #   spec_tag (string)

    def to_spec
      project.from_directory do
        output_dir = File.join("output", package_name)
        FileUtils.mkdir_p(output_dir)

        new_content = TemplateManager.new.generate(template_spec_name, binding)
        conflict_count = project.merge_new_content(new_content, spec_path,
                                                   "Spec generated", "generate_#{spec_tag}_spec")

        destination_spec_path = File.join(output_dir, "#{package_name}.spec")
        FileUtils.symlink(File.expand_path(spec_path), destination_spec_path, force: true)

        [spec_path, conflict_count]
      end
    end
  end
end
