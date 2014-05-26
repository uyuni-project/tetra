# encoding: UTF-8

module Gjp
  class MavenCommand < Gjp::BaseCommand
    parameter "[MAVEN OPTIONS] ...", "mvn options", attribute_name: "dummy"

    # override parsing in order to pipe everything to mvn
    def parse(args)
      @options = args
    end

    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        ensure_dry_running(true, project) do
          Gjp::MavenRunner.new(project).mvn(@options)
        end
      end
    end
  end
end
