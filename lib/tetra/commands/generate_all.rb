# encoding: UTF-8

module Tetra
  # tetra generate-all
  class GenerateAllCommand < Tetra::BaseCommand
    option %w(-f --filter), "FILTER", "filter files to be installed by this package spec", default: "*.jar"
    option %w(-w --whole), :flag, "recreate the whole archive (not incremental)"
    parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", default: "."
    parameter "[POM]", "a package pom file path", default: "pom.xml"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          package_name = project.get_package_name(directory)

          result_path = Tetra::Archiver.new(project).archive_kit(whole?)
          print_generation_result(project, result_path)

          result_path, conflict_count = Tetra::SpecGenerator.new(project).generate_kit_spec
          print_generation_result(project, result_path, conflict_count)

          history_file = File.join(Dir.home, ".bash_history")
          result_path, conflict_count = Tetra::ScriptGenerator.new(project, history_file)
            .generate_build_script(package_name)
          print_generation_result(project, result_path, conflict_count)

          result_path = Tetra::Archiver.new(project).archive_package package_name
          print_generation_result(project, result_path)

          result_path, conflict_count = Tetra::SpecGenerator.new(project)
            .generate_package_spec package_name, pom, filter
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end
  end
end
