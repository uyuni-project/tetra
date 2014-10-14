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
      "generate-kit-archive",
      "Create or refresh the kit tarballs",
      Tetra::GenerateKitArchiveCommand
    )

    subcommand(
      "generate-kit-spec",
      "Create or refresh the kit spec files",
      Tetra::GenerateKitSpecCommand
    )

    subcommand(
      "generate-package-script",
      "Create or refresh the package build.sh file",
      Tetra::GeneratePackageScriptCommand
    )

    subcommand(
      "generate-package-archive",
      "Create or refresh the package tarball",
      Tetra::GeneratePackageArchiveCommand
    )

    subcommand(
      "generate-package-spec",
      "Create or refresh the package spec file",
      Tetra::GeneratePackageSpecCommand
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
