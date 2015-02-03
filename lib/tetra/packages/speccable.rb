# encoding: UTF-8

module Tetra
  # adds methods to generate a spec file from a package object
  module Speccable
    # saves a specfile for this object in correct directories
    # returns the spec path and the conflict count with the previously generated
    # version, if any
    # destination_dir/name/name.spec
    def _to_spec(project, name, template_spec_name, destination_dir)
      project.from_directory do
        spec_name = "#{name}.spec"
        spec_dir = File.join(destination_dir, name)
        FileUtils.mkdir_p(spec_dir)

        spec_path = File.join(spec_dir, spec_name)

        new_content = generate(template_spec_name, binding)
        label = "Spec for #{name} generated"
        conflict_count = project.merge_new_content(new_content, spec_path,
                                                   label, "#{name}-spec")
        [spec_path, conflict_count]
      end
    end

    # returns the spec template path, exposed for testing
    def template_path
      File.join(File.dirname(__FILE__), "..", "..", "template")
    end

    private

    # generates content from an ERB template and an object binding
    # if destination_path is given, write it to that file, otherwise just
    # return it
    def generate(template_name, object_binding, destination_path = nil)
      erb = ERB.new File.read(File.join(template_path, template_name)), nil, "<>"
      new_content =  erb.result(object_binding)

      unless destination_path.nil?
        File.open(destination_path, "w") { |io| io.write new_content }
      end

      new_content
    end
  end
end
