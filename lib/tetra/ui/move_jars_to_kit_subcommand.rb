# encoding: UTF-8

module Tetra
  # tetra move-jars-to-kit
  class MoveJarsToKitSubcommand < Tetra::Subcommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")

        ensure_dry_running(false, project) do
          project.purge_jars.each do |original, final|
            puts "Replaced #{original} with symlink pointing to to #{final}"
          end
        end
      end
    end
  end
end
