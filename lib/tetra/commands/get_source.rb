# encoding: UTF-8

module Tetra
  # tetra get-source
  class GetSourceCommand < Tetra::BaseCommand
    parameter "POM", "a pom file path or URI"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        source_getter = Tetra::SourceGetter.new

        puts "Attempting to find source through Maven..."
        if source_getter.get_maven_source_jar(project, pom)
          puts "Source jar found and added to Maven repository."
        else
          mvn_path = Tetra::Kit.new(project).find_executable("mvn")
          mvn = Tetra::Mvn.new(project.full_path, mvn_path)
          effective_pom_path = mvn.get_effective_pom(pom)
          puts "Source jar not found in Maven. Try looking here:"
          pom = Tetra::Pom.new(effective_pom_path)
          puts "Website: #{pom.url}" unless pom.url.empty?
          puts "SCM connection: #{pom.scm_connection}" unless pom.scm_connection.empty?
          puts "SCM connection: #{pom.scm_url}" unless pom.scm_url.empty?
          puts "The effective POM: #{effective_pom_path}"
          name = !pom.name.empty? ? pom.name : pom.artifact_id
          puts "Google: http://google.com/#q=#{URI.encode("#{name} sources")}"
        end
      end
    end
  end
end
