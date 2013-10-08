# encoding: UTF-8

module Gjp
  # creates and updates spec files
  class SpecGenerator
    include Logger

    def initialize(project)
      @project = project
      @git = Gjp::Git.new(@project.full_path)
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

    # generates a file in result_path from template together with binding.
    # if a file already exists at that position, 3-way merge it with the
    # common ancestor. Takes a snapshot in the end for future merges
    def generate_merging(template, binding, result_path, tag_prefix)
      @project.from_directory do
        already_existing = File.exist? result_path
        previous_tag = @project.latest_tag(tag_prefix)

        if already_existing
          File.rename result_path, "#{result_path}.gjp_user_edited"
        end

        TemplateManager.new.generate template, binding, result_path
        @project.take_snapshot("Spec generated", tag_prefix)

        if already_existing
          if previous_tag == ""
            previous_tag = @project.latest_tag(tag_prefix)
          end

          # 3-way merge
          conflict_count = @git.merge_with_tag("#{result_path}", "#{result_path}.gjp_user_edited", previous_tag)
          File.delete "#{result_path}.gjp_user_edited"
          return conflict_count
        end
        return 0
      end
    end
  end
end
