# encoding: UTF-8

module Gjp
  # gjp dry-run
  class DryRunCommand < Gjp::BaseCommand
    def execute
      checking_exceptions do
        if Gjp::Project.new(".").dry_run
          puts "Now dry-running, please start your build."
          puts "To run a Maven installation from the kit, use \"gjp mvn\"."
          puts "If the build succeedes end this dry run with \"gjp finish\"."
          puts "If the build does not succeed use \"gjp finish --abort\" to restore files."
        end
      end
    end
  end
end
