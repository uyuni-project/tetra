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

    # saves a specfile for this object in correct directories
    # returns the spec path and the conflict count with the previously generated
    # version, if any
    def to_spec
      project.from_directory do
        output_dir = File.join("output", package_name)
        FileUtils.mkdir_p(output_dir)

        new_content = generate(template_spec_name, binding)
        conflict_count = project.merge_new_content(new_content, spec_path,
                                                   "Spec generated", "generate_#{spec_tag}_spec")

        destination_spec_path = File.join(output_dir, "#{package_name}.spec")
        FileUtils.symlink(File.expand_path(spec_path), destination_spec_path, force: true)

        [spec_path, conflict_count]
      end
    end

    # returns the spec template path, exposed for testing
    def template_path
      File.join(File.dirname(__FILE__), "..", "template")
    end

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
