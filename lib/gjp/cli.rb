# encoding: UTF-8

require 'clamp'

class MainCommand < Clamp::Command
  subcommand "greet", "Greets you" do
    def execute
      p "Hallo!"
    end
  end
end
