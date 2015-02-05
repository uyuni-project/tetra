# encoding: UTF-8

module Tetra
  # tetra generate-all
  class GenerateAllSubcommand < Tetra::Subcommand
    option %w(-f --filter), "FILTER", "filter files to be installed by this package spec", default: "*.jar"
    parameter "[POM]", "a package pom file path", default: "pom.xml"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(:has_finished, project) do
          GenerateKitSubcommand.new(@invocation_path).execute

          GenerateScriptSubcommand.new(@invocation_path).execute

          GenerateArchiveSubcommand.new(@invocation_path).execute

          command = GenerateSpecSubcommand.new(@invocation_path)
          command.filter = filter
          command.pom = pom
          command.execute
        end
      end
    end
  end
end
