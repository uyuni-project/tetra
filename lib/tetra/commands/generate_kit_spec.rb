# encoding: UTF-8

module Tetra
  # tetra generate-kit-spec
  class GenerateKitSpecCommand < Tetra::BaseCommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          kit = Tetra::Kit.new(project)
          result_path, conflict_count = kit.to_spec
          print_generation_result(project, result_path, conflict_count)

          kit.items.each do |item|
            result_path, conflict_count = item.to_spec
            print_generation_result(project, result_path, conflict_count)
          end
        end
      end
    end
  end
end
