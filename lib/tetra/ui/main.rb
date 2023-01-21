# frozen_string_literal: true

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
      "patch",
      "Saves changes in source files for inclusion in a patch",
      Tetra::PatchSubcommand
    )

    subcommand(
      "change-sources",
      "Swaps the sources for this package with new ones",
      Tetra::ChangeSourcesSubcommand
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
