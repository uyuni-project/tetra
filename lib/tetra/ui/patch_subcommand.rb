# encoding: UTF-8

module Tetra
  # tetra patch
  class PatchSubcommand < Tetra::Subcommand
    option %w(-n --new-tarball), :flag, "suppress patch creation, roll all changes so far in the tarball"
    parameter "[MESSAGE]", "a short patch description", default: "Sources updated"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(:is_not_in_progress, project) do
          project.commit_sources(message, new_tarball?)
        end
      end
    end
  end
end
