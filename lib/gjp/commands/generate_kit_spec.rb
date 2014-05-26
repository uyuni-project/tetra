# encoding: UTF-8

module Gjp
  class GenerateKitSpecCommand < Gjp::BaseCommand
    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        ensure_dry_running(false, project) do
          result_path, conflict_count = Gjp::SpecGenerator.new(project).generate_kit_spec
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end
  end
end
