# encoding: UTF-8

module Tetra
  # tetra download-maven-source-jars
  class DownloadMavenSourceJarsCommand < Tetra::BaseCommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        source_getter = Tetra::SourceGetter.new

        ensure_dry_running(false, project) do
          puts "Getting sources from Maven..."
          succeeded, failed = source_getter.get_maven_source_jars(project)

          puts "\n**SUMMARY**\n"
          puts "Sources found for:"
          succeeded.each do |path|
            puts " #{format_path(path, project)}"
          end

          puts "\nSources not found for:"
          failed.each do |path|
            puts " #{format_path(path, project)}"
          end
        end
      end
    end
  end
end
