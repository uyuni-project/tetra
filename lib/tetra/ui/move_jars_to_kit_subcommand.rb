# frozen_string_literal: true

module Tetra
  # tetra move-jars-to-kit
  class MoveJarsToKitSubcommand < Tetra::Subcommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")

        ensure_dry_running(:is_not_in_progress, project) do
          project.purge_jars.each do |original, final|
            puts "Replaced #{original} with symlink pointing to #{final}"
          end
        end
      end
    end
  end
end
