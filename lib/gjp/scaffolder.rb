# encoding: UTF-8

module Gjp
  # creates and updates spec files
  class Scaffolder
    include Logger

    def initialize(project)
      @project = project
    end

    def scaffold_kit_spec
      if @project.get_status != :gathering
        return false
      end

      @project.from_directory do
        spec_path = File.join("specs", "#{@project.name}-kit.spec")

        TemplateManager.new.generate "kit.spec", @project.get_binding, "#{spec_path}.new_scaffold"

        already_scaffolded = @project.latest_tag(:scaffold_kit_spec) != ""
        already_existing = File.exist? spec_path

        if already_scaffolded and already_existing
          # 3-way merge
          `git show #{@project.latest_tag(:scaffold_kit_spec)}:#{spec_path} > #{spec_path}.old_scaffold`
          `git merge-file --ours #{spec_path} #{spec_path}.old_scaffold #{spec_path}.new_scaffold`
          File.delete "#{spec_path}.new_scaffold"
          File.delete "#{spec_path}.old_scaffold"
        else
          # just replace
          File.rename "#{spec_path}.new_scaffold", spec_path
        end

        @project.take_snapshot "Kit spec scaffolded", :scaffold_kit_spec

        true
      end
    end
  end
end
