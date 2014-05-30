# encoding: UTF-8

module Gjp
  # gjp get-source
  class GetSourceCommand < Gjp::BaseCommand
    parameter "POM", "a pom file path or URI"

    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        source_getter = Gjp::SourceGetter.new

        puts "Attempting to find source through Maven..."
        if source_getter.get_maven_source_jar(project, pom)
          puts "Source jar found and added to Maven repository."
        else
          effective_pom_path = Gjp::MavenRunner.new(project).get_effective_pom(pom)
          puts "Source jar not found in Maven. Try looking here:"
          pom = Gjp::Pom.new(effective_pom_path)
          unless pom.url.empty?
            puts "Website: #{pom.url}"
          end
          unless pom.scm_connection.empty?
            puts "SCM connection: #{pom.scm_connection}"
          end
          unless pom.scm_url.empty?
            puts "SCM connection: #{pom.scm_url}"
          end
          puts "The effective POM: #{effective_pom_path}"
          puts "Google: http://google.com/#q=#{URI.encode(pom.name + " sources")}"
        end
      end
    end
  end
end
