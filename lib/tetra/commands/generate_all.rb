# encoding: UTF-8

module Tetra
  # tetra generate-all
  class GenerateAllCommand < Tetra::BaseCommand
    option %w(-f --filter), "FILTER", "filter files to be installed by this package spec", default: "*.jar"
    parameter "[POM]", "a package pom file path", default: "pom.xml"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(false, project) do
          GenerateKitArchiveCommand.new(@invocation_path).execute

          GenerateKitSpecCommand.new(@invocation_path).execute

          script_command = GeneratePackageScriptCommand.new(@invocation_path)
          script_command.execute

          archive_command = GeneratePackageArchiveCommand.new(@invocation_path)
          archive_command.execute

          archive_command = GeneratePackageSpecCommand.new(@invocation_path)
          archive_command.filter = filter
          archive_command.pom = pom
          archive_command.execute
        end
      end
    end
  end
end
