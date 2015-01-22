# encoding: UTF-8

module Tetra
  # tetra ant
  class AntSubcommand < Tetra::Subcommand
    parameter "[ANT OPTIONS] ...", "ant options", attribute_name: "dummy"

    # options will be parsed by ant
    def parse(args)
      bypass_parsing(args)
    end

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(true, project) do
          path = Tetra::Kit.new(project).find_executable("ant")
          Tetra::Ant.new(project.full_path, path).ant(@options)
        end
      end
    end
  end
end
