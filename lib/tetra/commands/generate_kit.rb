# encoding: UTF-8

module Tetra
  # tetra generate-kit
  class GenerateKitCommand < Tetra::BaseCommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          Tetra::Kit.new(project).items.each do |item|
            result_path, conflict_count = item.to_spec
            print_generation_result(project, result_path, conflict_count)

            result_path = item.to_archive
            print_generation_result(project, result_path)
          end
        end
      end
    end
  end
end
