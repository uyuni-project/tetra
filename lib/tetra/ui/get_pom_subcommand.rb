# frozen_string_literal: true

require "uri"

module Tetra
  # tetra get-pom
  class GetPomSubcommand < Tetra::Subcommand
    parameter "NAME", "a jar file name or a `name-version` string (heuristic)"

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(:is_not_in_progress, project) do
          pom_getter = Tetra::PomGetter.new
          path, status = pom_getter.get_pom(name)

          if path
            text_status = case status
                          when :found_in_jar
                            "was inside the jar"
                          when :found_via_sha1
                            "found by sha1 search from search.maven.org"
                          when :found_via_heuristic
                            "found by heuristic search from search.maven.org"
                          end

            puts "#{format_path(path, project)} written, #{text_status}"
          else
            puts "#{name}'s pom not found. Try:"

            # URI.encode_www_form_component correctly escapes spaces to '+' for query params.
            clean_name = pom_getter.cleanup_name(name)
            query = "#{clean_name} pom"
            puts "http://google.com/#q=#{URI.encode_www_form_component(query)}"
          end
        end
      end
    end
  end
end
