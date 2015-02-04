# encoding: UTF-8

module Tetra
  # tetra commit-source
  class CommitSourceSubcommand < Tetra::Subcommand
    option %w(-p --as-patch), :flag, "put changes in sources in a new patch"
    option %w(-t --as-tarball), :flag, "include all changes so far in the source tarball"
    parameter "[MESSAGE]", "a commit message", default: "Sources updated"

    def execute
      if as_patch? == as_tarball?
        puts "You must specify either --as-patch or --as-tarball exclusively"
        return
      end

      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          project.commit_sources(as_patch?, message)
        end
      end
    end
  end
end
