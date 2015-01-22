# encoding: UTF-8

module Tetra
  # tetra mvn
  class MvnSubcommand < Tetra::Subcommand
    parameter "[MAVEN OPTIONS] ...", "mvn options", attribute_name: "dummy"

    # options will be parsed by mvn
    def parse(args)
      bypass_parsing(args)
    end

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(true, project) do
          path = Tetra::Kit.new(project).find_executable("mvn")
          Tetra::Mvn.new(project.full_path, path).mvn(@options)
        end
      end
    end
  end
end
