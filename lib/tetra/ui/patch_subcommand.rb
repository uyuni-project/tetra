# encoding: UTF-8

module Tetra
  # tetra patch
  class PatchSubcommand < Tetra::Subcommand
    parameter "[MESSAGE]", "a short patch description", default: "Sources updated"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(:is_not_in_progress, project) do
          project.commit_sources(message, false)
        end
      end
    end
  end
end
