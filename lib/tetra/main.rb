# encoding: UTF-8

module Tetra
  # program entry point
  class MainCommand < Clamp::Command
    subcommand(
      "init",
      "Inits a tetra project in the current directory",
      Tetra::InitCommand
    )

    subcommand(
      "dry-run",
      "Starts a dry-run build",
      Tetra::DryRunCommand
    )

    subcommand(
      "mvn",
      "Locates and runs Maven from any directory in kit/",
      Tetra::MavenCommand
    )

    subcommand(
      "ant",
      "Locates and runs Ant from any directory in kit/",
      Tetra::AntCommand
    )

    subcommand(
      "finish",
      "Ends the current dry-run",
      Tetra::FinishCommand
    )

    subcommand(
      "generate-kit",
      "Create or refresh the kit spec and archive files",
      Tetra::GenerateKitCommand
    )

    subcommand(
      "generate-script",
      "Create or refresh the package build.sh file",
      Tetra::GenerateScriptCommand
    )

    subcommand(
      "generate-archive",
      "Create or refresh the package tarball",
      Tetra::GenerateArchiveCommand
    )

    subcommand(
      "generate-spec",
      "Create or refresh the package spec file",
      Tetra::GenerateSpecCommand
    )

    subcommand(
      "generate-all",
      "Create or refresh all specs, archives, scripts",
      Tetra::GenerateAllCommand
    )

    subcommand(
      "move-jars-to-kit",
      "Locates jars in src/ and moves them to kit/",
      Tetra::MoveJarsToKitCommand
    )

    subcommand(
      "download-maven-source-jars",
      "Attempts to download Maven kit/ sources",
      Tetra::DownloadMavenSourceJarsCommand
    )

    subcommand(
      "get-pom",
      "Retrieves a pom file",
      Tetra::GetPomCommand
    )

    subcommand(
      "get-source",
      "Attempts to retrieve a project's sources",
      Tetra::GetSourceCommand
    )

    subcommand(
      "list-kit-missing-sources",
      "Locates jars in kit/ that have no source files",
      Tetra::ListKitMissingSourcesCommand
    )
  end
end
