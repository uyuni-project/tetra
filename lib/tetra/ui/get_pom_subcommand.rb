# encoding: UTF-8

module Tetra
  # tetra get-pom
  class GetPomSubcommand < Tetra::Subcommand
    parameter "NAME", "a jar file name or a `name-version` string (heuristic)"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        pom_getter = Tetra::PomGetter.new

        path, status = pom_getter.get_pom(name)
        if path
          text_status = (
            if status == :found_in_jar
              "was inside the jar"
            elsif status == :found_via_sha1
              "found by sha1 search from search.maven.org"
            elsif status == :found_via_heuristic
              "found by heuristic search from search.maven.org"
            end
          )

          puts "#{format_path(path, project)} written, #{text_status}"
        else
          puts "#{name}'s pom not found. Try:"
          puts "http://google.com/#q=#{URI.encode(pom_getter.cleanup_name(name) + ' pom')}"
        end
      end
    end
  end
end
