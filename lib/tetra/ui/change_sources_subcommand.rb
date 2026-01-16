# frozen_string_literal: true

module Tetra
  # tetra change-sources
  class ChangeSourcesSubcommand < Tetra::Subcommand
    parameter "[SOURCE_ARCHIVE]", "new source tarball or zipfile"
    parameter "[MESSAGE]", "a short change description", default: "Sources changed"
    option %w(-n --no-archive), :flag, "use current src/ contents instead of an archive (see SPECIAL_CASES.md)",
           default: false

    def execute
      checking_exceptions do
        # Ensure the user provided an archive OR explicitly opted out
        if source_archive.nil? && !no_archive?
          signal_usage_error "please specify a source archive file or use \"--no-archive\" (see SPECIAL_CASES.md)."
        end

        project = Tetra::Project.new(".")
        ensure_dry_running(:is_not_in_progress, project) do
          if !no_archive?
            # CASE 1: Updating from a new archive file
            full_archive_path = File.expand_path(source_archive)
            project.commit_source_archive(full_archive_path, message)

            puts "New sources committed."
            puts "Please delete any stale source archives from packages/ before proceeding."
          else
            # CASE 2: Updating from manual changes in src/
            project.commit_sources(message, true)

            puts "New sources committed."
            puts "Please copy source archive(s) corresponding to src/ in packages/ before proceeding."
          end
        end
      end
    end
  end
end
