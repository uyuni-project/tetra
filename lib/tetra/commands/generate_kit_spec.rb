# encoding: UTF-8

module Tetra
  # tetra generate-kit-spec
  class GenerateKitSpecCommand < Tetra::BaseCommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          result_path, conflict_count = Tetra::SpecGenerator.new(project).generate_kit_spec
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end
  end
end
