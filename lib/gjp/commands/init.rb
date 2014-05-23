# encoding: UTF-8

module Gjp
  class InitCommand < Gjp::BaseCommand

    def execute
      checking_exceptions do
        Gjp::Project.init(".")
        puts "Project inited."
        puts "Add sources to src/<package name>, binary dependencies to kit/."
        puts "When you are ready to test a build, use \"gjp dry-run\"."
      end
    end
  end
end
