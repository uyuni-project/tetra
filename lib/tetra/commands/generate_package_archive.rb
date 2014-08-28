# encoding: UTF-8

module Tetra
  # tetra generate-package-archive
  class GeneratePackageArchiveCommand < Tetra::BaseCommand
    parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", default: "."

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          package_name = project.get_package_name(directory)
          result_path = Tetra::Package.new(project, package_name).to_archive
          print_generation_result(project, result_path)
        end
      end
    end
  end
end
