# encoding: UTF-8

module Tetra
  # tetra ant
  class AntCommand < Tetra::BaseCommand
    parameter "[ANT OPTIONS] ...", "ant options", attribute_name: "dummy"

    # override parsing in order to pipe everything to mvn
    # rubocop:disable TrivialAccessors
    def parse(args)
      @options = args
    end

    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        ensure_dry_running(true, project) do
          Tetra::AntRunner.new(project).ant(@options)
        end
      end
    end
  end
end
