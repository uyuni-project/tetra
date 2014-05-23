# encoding: UTF-8

module Gjp
  class AntCommand < Gjp::BaseCommand
    parameter "[ANT OPTIONS] ...", "ant options", :attribute_name => "dummy"

    # override parsing in order to pipe everything to mvn
    def parse(args)
      @options = args
    end

    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        ensure_dry_running(true, project) do
          Gjp::AntRunner.new(project).ant(@options)
        end
      end
    end
  end
end
