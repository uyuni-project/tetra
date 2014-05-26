# encoding: UTF-8

module Gjp
  class GeneratePackageScriptCommand < Gjp::BaseCommand

    parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", :default => "."

    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        ensure_dry_running(false, project) do
          package_name = project.get_package_name(directory)
          history_file = File.join(Dir.home, ".bash_history")
          result_path, conflict_count = Gjp::ScriptGenerator.new(project, history_file)
            .generate_build_script(package_name)
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end
  end
end
