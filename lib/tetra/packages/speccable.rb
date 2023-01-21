# frozen_string_literal: true

module Tetra
  # adds methods to generate a spec file from a package object
  module Speccable
    include Tetra::Generatable

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
  end
end
