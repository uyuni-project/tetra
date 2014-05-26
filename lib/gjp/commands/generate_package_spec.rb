# encoding: UTF-8

module Gjp
  class GeneratePackageSpecCommand < Gjp::BaseCommand
    option ["-f", "--filter"], "FILTER", "filter files to be installed by this spec", default: "*.jar"
    parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", default: "."
    parameter "[POM]", "a pom file path", default: "pom.xml"

    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        ensure_dry_running(false, project) do
          package_name = project.get_package_name(directory)
          result_path, conflict_count = Gjp::SpecGenerator.new(project)
            .generate_package_spec(package_name, pom, filter)
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end
  end
end
