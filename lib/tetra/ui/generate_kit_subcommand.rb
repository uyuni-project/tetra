# encoding: UTF-8

module Tetra
  # tetra generate-kit
  class GenerateKitSubcommand < Tetra::Subcommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          kit = Tetra::KitPackage.new(project)
          result_path, conflict_count = kit.to_spec
          print_generation_result(project, result_path, conflict_count)

          result_path = kit.to_archive
          print_generation_result(project, result_path)
        end
      end
    end
  end
end
