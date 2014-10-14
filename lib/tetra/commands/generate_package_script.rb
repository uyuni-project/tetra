# encoding: UTF-8

module Tetra
  # tetra generate-package-script
  class GeneratePackageScriptCommand < Tetra::BaseCommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          history_file = File.join(Dir.home, ".bash_history")
          result_path, conflict_count = Tetra::ScriptGenerator.new(project, history_file)
            .generate_build_script
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end
  end
end
