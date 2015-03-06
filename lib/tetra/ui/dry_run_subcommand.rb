# encoding: UTF-8

module Tetra
  # tetra dry-run
  class DryRunSubcommand < Tetra::Subcommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")

        if project.src_patched?
          puts "Some files in src/ were changed since last dry-run."
          puts "Use \"tetra patch message\" to include changes in a patch before dry-running."
          puts "Dry run not started."
        else
          project.dry_run
          puts "Dry-run started in a new bash shell."
          puts "Build your project now, you can use \"tetra mvn\" and \"tetra ant\"."
          puts "If the build succeedes end this dry run with ^D (Ctrl+D)."
          puts "If the build does not succeed use ^C^D to abort and undo any change."

          begin
            history = Bash.new.bash
            project.finish(history)
            puts "Dry-run finished."
          rescue ExecutionFailed
            project.abort
            puts "Project reverted as before dry-run."
          end
        end
      end
    end
  end
end
