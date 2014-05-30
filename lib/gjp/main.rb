# encoding: UTF-8
require "clamp"

module Gjp
  # program entry point
  class MainCommand < Clamp::Command
    subcommand(
      "init",
      "Inits a gjp project in the current directory",
      Gjp::InitCommand
    )

    subcommand(
      "dry-run",
      "Starts a dry-run build",
      Gjp::DryRunCommand
    )

    subcommand(
      "mvn",
      "Locates and runs Maven from any directory in kit/",
      Gjp::MavenCommand
    )

    subcommand(
      "ant",
      "Locates and runs Ant from any directory in kit/",
      Gjp::AntCommand
    )

    subcommand(
      "finish",
      "Ends the current dry-run",
      Gjp::FinishCommand
    )

    subcommand(
      "generate-kit-archive",
      "Create or refresh the kit tarball",
      Gjp::GenerateKitArchiveCommand
    )

    subcommand(
      "generate-kit-spec",
      "Create or refresh a spec file for the kit",
      Gjp::GenerateKitSpecCommand
    )

    subcommand(
      "generate-package-script",
      "Create or refresh a build.sh file for a package",
      Gjp::GeneratePackageScriptCommand
    )

    subcommand(
      "generate-package-archive",
      "Create or refresh a package tarball",
      Gjp::GeneratePackageArchiveCommand
    )

    subcommand(
      "generate-package-spec",
      "Create or refresh a spec file for a package",
      Gjp::GeneratePackageSpecCommand
    )

    subcommand(
      "generate-all",
      "Create or refresh specs, archives, scripts for a package and the kit",
      Gjp::GenerateAllCommand
    )

    subcommand(
      "move-jars-to-kit",
      "Locates jars in src/ and moves them to kit/",
      Gjp::MoveJarsToKitCommand
    )

    subcommand(
      "download-maven-source-jars",
      "Attempts to download Maven kit/ sources",
      Gjp::DownloadMavenSourceJarsCommand
    )

    subcommand(
      "get-pom",
      "Retrieves a pom file",
      Gjp::GetPomCommand
    )

    subcommand(
      "get-source",
      "Attempts to retrieve a project's sources",
      Gjp::GetSourceCommand
    )

    subcommand(
      "list-kit-missing-sources",
      "Locates jars in kit/ that have no source files",
      Gjp::ListKitMissingSourcesCommand
    )
  end
end
