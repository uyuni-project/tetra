# encoding: UTF-8

module Tetra
  # tetra generate-spec
  class GenerateSpecSubcommand < Tetra::Subcommand
    option %w(-f --filter), "FILTER", "filter files to be installed by this spec", default: "*.jar"
    parameter "[POM]", "a pom file path", default: "pom.xml"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(:has_finished, project) do
          package = Tetra::Package.new(project, pom, filter)
          patches = package.to_patches

          patches.each do |patch|
            print_generation_result(project, patch)
          end

          result_path, conflict_count = package.to_spec
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end
  end
end
