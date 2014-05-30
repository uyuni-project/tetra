# encoding: UTF-8

module Gjp
  class GenerateKitArchiveCommand < Gjp::BaseCommand
    option %w(-w --whole), :flag, "recreate the whole archive (not incremental)"

    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        ensure_dry_running(false, project) do
          result_path = Gjp::Archiver.new(project).archive_kit(whole?)
          print_generation_result(project, result_path)
        end
      end
    end
  end
end
