# encoding: UTF-8

require 'clamp'

class MainCommand < Clamp::Command
  subcommand "get-pom", "Retrieves a pom file for an archive or project directory" do
    parameter "[PATH]", "project directory or jar file path", :default => "."

    def execute
      puts PomGetter.get_pom(path)
    end
  end
end
