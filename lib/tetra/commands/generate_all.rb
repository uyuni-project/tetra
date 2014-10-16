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
          GenerateKitCommand.new(@invocation_path).execute

          GeneratePackageScriptCommand.new(@invocation_path).execute

          GeneratePackageArchiveCommand.new(@invocation_path).execute

          command = GeneratePackageSpecCommand.new(@invocation_path)
          command.filter = filter
          command.pom = pom
          command.execute
        end
      end
    end
  end
end
