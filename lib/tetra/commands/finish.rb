# encoding: UTF-8

module Tetra
  # tetra finish
  class FinishCommand < Tetra::BaseCommand
    option %w(-a --abort), :flag, "abort build, restore files as before dry-run"

    def execute
      checking_exceptions do
        if Tetra::Project.new(".").finish(abort?)
          if abort?
            puts "Project reverted as before dry-run."
          else
            puts "Dry-run finished."
          end
        else
          puts "No dry-run is in progress."
        end
      end
    end
  end
end
