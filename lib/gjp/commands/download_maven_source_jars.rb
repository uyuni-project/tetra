# encoding: UTF-8

module Gjp
  # gjp download-maven-source-jars
  class DownloadMavenSourceJarsCommand < Gjp::BaseCommand
    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        source_getter = Gjp::SourceGetter.new

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
