# encoding: UTF-8

module Tetra
  # tetra init
  class InitCommand < Tetra::BaseCommand
    def execute
      checking_exceptions do
        Tetra::Project.init(".")
        puts "Project inited."
        puts "Add sources to src/, binary dependencies to kit/."
        puts "When you are ready to test a build, use \"tetra dry-run\"."
      end
    end
  end
end
