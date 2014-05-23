# encoding: UTF-8

module Gjp
  class GeneratePackageArchiveCommand < Gjp::BaseCommand

    parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", :default => "."

    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        ensure_dry_running(false, project) do
          package_name = project.get_package_name(directory)
          result_path = Gjp::Archiver.new(project).archive_package package_name
          print_generation_result(project, result_path)
        end
      end
    end
  end
end
