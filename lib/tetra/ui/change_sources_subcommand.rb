# encoding: UTF-8

module Tetra
  # tetra change-sources
  class ChangeSourcesSubcommand < Tetra::Subcommand
    parameter "[SOURCE_ARCHIVE]", "new source tarball or zipfile"
    parameter "[MESSAGE]", "a short change description", default: "Sources changed"
    option %w(-n --no-archive), :flag, "use current src/ contents instead of an archive (see SPECIAL_CASES.md)",
           default: false

    def execute
      if source_archive.nil? && no_archive? == false
        signal_usage_error "please specify a source archive file or use \"--no-archive\" (see SPECIAL_CASES.md)."
      end

      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(:is_not_in_progress, project) do
          if no_archive? == false
            project.commit_source_archive(File.expand_path(source_archive), message)
            puts "New sources committed."
            puts "Please delete any stale source archives from packages/ before proceeding."
          else
            project.commit_sources(message, true)
            puts "New sources committed."
            puts "Please copy source archive(s) corresponding to src/ in packages/ before proceeding."
          end
        end
      end
    end
  end
end
