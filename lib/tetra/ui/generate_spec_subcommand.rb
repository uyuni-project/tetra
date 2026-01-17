# frozen_string_literal: true

module Tetra
  # tetra generate-spec
  class GenerateSpecSubcommand < Tetra::Subcommand
    option %w(-f --filter), "FILTER", "filter files to be installed by this spec", default: "*.jar"
    parameter "[POM]", "a pom file path", default: "pom.xml"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(:has_finished, project) do
          patches = project.write_source_patches
          package = Tetra::Package.new(project, pom, filter, patches)

          patches.each do |patch|
            print_generation_result(project, patch)
          end

          result_path, conflict_count = package.to_spec
          print_generation_result(project, result_path, conflict_count)

          puts "Warning: #{pom} not found, some spec fields will be left blank" unless File.exist?(pom)
          puts "Warning: source archive not found, package will not build" unless project.src_archive
        end
      end
    end
  end
end
