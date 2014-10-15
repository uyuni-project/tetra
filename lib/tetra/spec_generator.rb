# encoding: UTF-8

module Tetra
  # implements a to_spec method
  module SpecGenerator
    # saves a specfile for this object in correct directories
    # returns the spec path and the conflict count with the previously generated
    # version, if any
    def _to_spec(project, package_name, spec_dir, template_spec_name)
      project.from_directory do
        spec_name = "#{package_name}.spec"
        spec_path = File.join(spec_dir, spec_name)

        new_content = generate(template_spec_name, binding)
        label = "Spec for #{package_name} generated"
        conflict_count = project.merge_new_content(new_content, spec_path,
                                                   label, "generate_#{package_name}_spec")

        output_dir = File.join("output", package_name)
        FileUtils.mkdir_p(output_dir)

        spec_link_path = File.join(output_dir, spec_name)
        FileUtils.symlink(File.expand_path(spec_path), spec_link_path, force: true)

        [spec_link_path, conflict_count]
      end
    end

    # returns the spec template path, exposed for testing
    def template_path
      File.join(File.dirname(__FILE__), "..", "template")
    end

    private

    # generates content from an ERB template and an object binding
    # if destination_path is given, write it to that file, otherwise just
    # return it
    def generate(template_name, object_binding, destination_path = nil)
      template_path = File.join(File.dirname(__FILE__), "..", "template")
      erb = ERB.new File.read(File.join(template_path, template_name)), nil, "<>"
      new_content =  erb.result(object_binding)

      unless destination_path.nil?
        File.open(destination_path, "w") { |io| io.write new_content }
      end

      new_content
    end
  end
end
