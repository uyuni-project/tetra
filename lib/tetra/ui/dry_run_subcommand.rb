# frozen_string_literal: true

module Tetra
  # tetra dry-run
  class DryRunSubcommand < Tetra::Subcommand
    option ["-s", "--script"], "SCRIPT", "Run these commands to build the project instead of the interactive shell"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")

        if project.src_patched?
          puts "Changes detected in src/, please use:"
          puts " \"tetra patch\" to include those changes in the package as a patch file"
          puts " \"tetra change-sources\" to completely swap the source archive."
          puts "Dry run not started."
        else
          project.dry_run

          if script
            puts "Scripted dry-run started."
          else
            puts "Dry-run started in a new bash shell. Build your project now!"
            puts "Note that:"
            puts " - \"mvn\" and \"ant\" are already bundled by tetra"
            puts " - you have to use \"gradlew\" instead of \"./gradlew\" to launch a Gradle wrapper"
            puts "If the build succeeds end this dry run with ^D (Ctrl+D),"
            puts "if the build does not succeed use ^C^D to abort and undo any change"
          end

          begin
            history = Tetra::Bash.new(project).bash(script)
            project.finish(history)
            puts "Dry-run finished"
          rescue ExecutionFailed
            project.abort
            puts "Project reverted as before dry-run"
          end
        end
      end
    end
  end
end
