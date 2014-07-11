# encoding: UTF-8

module Gjp
  # gjp finish
  class FinishCommand < Gjp::BaseCommand
    option %w(-a --abort), :flag, "build abort, restore files as before dry-run"

    def execute
      checking_exceptions do
        if Gjp::Project.new(".").finish(abort?)
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
