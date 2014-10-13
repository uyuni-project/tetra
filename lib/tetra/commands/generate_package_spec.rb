# encoding: UTF-8

module Tetra
  # tetra generate-package-spec
  class GeneratePackageSpecCommand < Tetra::BaseCommand
    option %w(-f --filter), "FILTER", "filter files to be installed by this spec", default: "*.jar"
    parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", default: "."
    parameter "[POM]", "a pom file path", default: "pom.xml"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          package_name = project.get_package_name(directory)
          result_path, conflict_count =
            Tetra::Package.new(project, package_name, pom, filter).to_spec
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end
  end
end
