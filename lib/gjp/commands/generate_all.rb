# encoding: UTF-8

module Gjp
  class GenerateAllCommand < Gjp::BaseCommand
    option ["-f", "--filter"], "FILTER", "filter files to be installed by this package spec", :default => "*.jar"
    option ["-f", "--full"], :flag, "create a full archive (not incremental)"
    parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", :default => "."
    parameter "[POM]", "a package pom file path", :default => "pom.xml"

    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        ensure_dry_running(false, project) do
          package_name = project.get_package_name(directory)

          result_path = Gjp::Archiver.new(project).archive_kit(full?)
          print_generation_result(project, result_path)

          result_path, conflict_count = Gjp::SpecGenerator.new(project).generate_kit_spec
          print_generation_result(project, result_path, conflict_count)

          history_file = File.join(Dir.home, ".bash_history")
          result_path, conflict_count = Gjp::ScriptGenerator.new(project, history_file)
            .generate_build_script(package_name)
          print_generation_result(project, result_path, conflict_count)

          result_path = Gjp::Archiver.new(project).archive_package package_name
          print_generation_result(project, result_path)

          result_path, conflict_count = Gjp::SpecGenerator.new(project)
            .generate_package_spec package_name, pom, filter
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end
  end
end
