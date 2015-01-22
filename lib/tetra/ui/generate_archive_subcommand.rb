# encoding: UTF-8

module Tetra
  # tetra generate-archive
  class GenerateArchiveSubcommand < Tetra::Subcommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          result_path = Tetra::Package.new(project).to_archive
          print_generation_result(project, result_path)
        end
      end
    end
  end
end
