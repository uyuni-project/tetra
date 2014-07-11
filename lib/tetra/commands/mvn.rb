# encoding: UTF-8

module Tetra
  # tetra mvn
  class MavenCommand < Tetra::BaseCommand
    parameter "[MAVEN OPTIONS] ...", "mvn options", attribute_name: "dummy"

    # override parsing in order to pipe everything to mvn
    # rubocop:disable TrivialAccessors
    def parse(args)
      @options = args
    end

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(true, project) do
          Tetra::MavenRunner.new(project).mvn(@options)
        end
      end
    end
  end
end
