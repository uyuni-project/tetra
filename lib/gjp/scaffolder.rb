# encoding: UTF-8

module Gjp
  # creates and updates spec files
  class Scaffolder
    include Logger

    def initialize(project)
      @project = project
    end

    def generate_kit_spec
      spec_path = File.join("specs", "#{@project.name}-kit.spec")
      generate_merging "kit.spec", @project.get_binding, spec_path, :generate_kit_spec
      spec_path
    end

    def generate_package_spec(name, pom, filter)
      spec_path = File.join("specs", "#{name}.spec")

      list_file = File.join(@project.full_path, "file_lists/#{name}_output")
      if not File.exist? list_file
        return nil
      end

      adapter = Gjp::PackageSpecAdapter.new(@project, name, Gjp::Pom.new(pom), filter)

      generate_merging "package.spec", adapter.get_binding, spec_path, "scaffold_#{name}_spec"

      spec_path
    end

    # generates a file in result_path from template together with binding.
    # if a file already exists at that position, 3-way merge it with the
    # version with the latest tag specified. Takes a snapshot in the end
    # for future merges
    def generate_merging(template, binding, result_path, tag)
      @project.from_directory do
        TemplateManager.new.generate template, binding, "#{result_path}.new_scaffold"

        already_scaffolded = @project.latest_tag(tag) != ""
        already_existing = File.exist? result_path

        if already_scaffolded and already_existing
          # 3-way merge
          `git show #{@project.latest_tag(tag)}:#{result_path} > #{result_path}.old_scaffold`
          `git merge-file --ours #{result_path} #{result_path}.old_scaffold #{result_path}.new_scaffold`
          File.delete "#{result_path}.new_scaffold"
          File.delete "#{result_path}.old_scaffold"
        else
          # just replace
          File.rename "#{result_path}.new_scaffold", result_path
        end

        @project.take_snapshot "Kit spec scaffolded", tag
      end
    end

  end
end
