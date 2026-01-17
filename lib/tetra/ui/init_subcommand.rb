# frozen_string_literal: true

module Tetra
  # tetra init
  class InitSubcommand < Tetra::Subcommand
    parameter "PACKAGE_NAME", "name of the package to create"
    parameter "[SOURCE_ARCHIVE]", "source tarball or zipfile"
    option %w(-n --no-archive), :flag, "create a project without a source archive (see SPECIAL_CASES.md)",
           default: false

    def execute
      checking_exceptions do
        # Ensure the user provided an archive OR explicitly opted out
        if source_archive.nil? && !no_archive?
          signal_usage_error "please specify a source archive file or use \"--no-archive\" (see SPECIAL_CASES.md)."
        end

        # Ensure the file exists if provided
        if source_archive && !File.readable?(source_archive)
          signal_usage_error "#{source_archive} is not a file or it is not readable."
        end

        Tetra::Project.init(package_name)
        project = Tetra::Project.new(package_name)
        puts "Project inited in #{package_name}/."

        if source_archive
          puts "Decompressing sources..."
          # Expand path immediately to ensure we reference the correct file
          # relative to where the command was run, not inside the new project dir.
          full_archive_path = File.expand_path(source_archive)

          project.commit_source_archive(full_archive_path, "Initial sources added from archive")
          puts "Sources decompressed in #{package_name}/src/, original archive copied in #{package_name}/packages/."
        else
          puts "Use \"tetra change-sources\" to add sources to this project."
        end

        puts "Please add any other precompiled build dependency to kit/."
        puts "When you are ready to test a build, use \"tetra dry-run\" from the project directory"
      end
    end
  end
end
