# encoding: UTF-8

module Tetra
  # tetra dry-run
  class DryRunCommand < Tetra::BaseCommand
    def execute
      checking_exceptions do
        if Tetra::Project.new(".").dry_run
          puts "Now dry-running, please start your build."
          puts "To run a Maven installation from the kit, use \"tetra mvn\"."
          puts "If the build succeedes end this dry run with \"tetra finish\"."
          puts "If the build does not succeed use \"tetra finish --abort\" to restore files."
        end
      end
    end
  end
end
