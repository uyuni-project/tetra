# encoding: UTF-8

module Tetra
  # program entry point
  class MainCommand < Clamp::Command
    subcommand(
      "init",
      "Inits a tetra project in the current directory",
      Tetra::InitSubcommand
    )

    subcommand(
      "dry-run",
      "Starts or ends a dry-run build",
      Tetra::DryRunSubcommand
    )

    subcommand(
      "mvn",
      "Locates and runs Maven from any directory in kit/",
      Tetra::MvnSubcommand
    )

    subcommand(
      "ant",
      "Locates and runs Ant from any directory in kit/",
      Tetra::AntSubcommand
    )

    subcommand(
      "generate-kit",
      "Create or refresh the kit spec and archive files",
      Tetra::GenerateKitSubcommand
    )

    subcommand(
      "generate-script",
      "Create or refresh the package build.sh file",
      Tetra::GenerateScriptSubcommand
    )

    subcommand(
      "generate-archive",
      "Create or refresh the package tarball",
      Tetra::GenerateArchiveSubcommand
    )

    subcommand(
      "generate-spec",
      "Create or refresh the package spec file",
      Tetra::GenerateSpecSubcommand
    )

    subcommand(
      "generate-all",
      "Create or refresh all specs, archives, scripts",
      Tetra::GenerateAllSubcommand
    )

    subcommand(
      "commit-sources",
      "Marks changes in source files",
      Tetra::CommitSourcesSubcommand
    )

    subcommand(
      "move-jars-to-kit",
      "Locates jars in src/ and moves them to kit/",
      Tetra::MoveJarsToKitSubcommand
    )

    subcommand(
      "get-pom",
      "Retrieves a pom file",
      Tetra::GetPomSubcommand
    )
  end
end
