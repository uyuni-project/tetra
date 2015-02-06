# encoding: UTF-8

module Tetra
  # tetra dry-run
  class DryRunSubcommand < Tetra::Subcommand
    parameter "COMMAND", "\"start\" to begin, \"finish\" to end or \"abort\" to undo changes" do |command|
      if %w(start finish abort).include?(command)
        command
      else
        fail ArgumentError, "\"#{command}\" is not valid, must be one of \"start\", \"finish\" or \"abort\""
      end
    end

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        send(command, project)
      end
    end

    def start(project)
      if !project.dry_running?
        if project.src_patched?
          puts "Some files in src/ were changed since last dry-run."
          puts "Use \"tetra patch message\" to include changes in a patch before dry-running."
          puts "Dry run not started."
        else
          project.dry_run
          puts "Now dry-running, please start your build."
          puts "To run a Maven installation from the kit, use \"tetra mvn\"."
          puts "If the build succeedes end this dry run with \"tetra dry-run finish\"."
          puts "If the build does not succeed use \"tetra dry-run abort\" to undo any change."
        end
      else
        puts "Dry-run already in progress."
        puts "Use \"tetra dry-run finish\" to end it or \"tetra dry-run abort\" to undo changes."
      end
    end

    def finish(project)
      if project.dry_running?
        project.finish
        puts "Dry-run finished."
      else
        puts "No dry-run is in progress."
      end
    end

    def abort(project)
      if project.dry_running?
        project.abort
        puts "Project reverted as before dry-run."
      else
        puts "No dry-run is in progress."
      end
    end
  end
end
