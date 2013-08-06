# encoding: UTF-8

require 'find'

module Gjp
  # encapsulates a Gjp project directory
  class Project
    def initialize(dir)
      @dir = dir
    end

    # inits a new project directory structure
    def init
      Dir.chdir(@dir) do
        `git init`

        Dir.mkdir("src")
        File.open(File.join("src", "README"), "w") do |file|
          file.puts "Sources are to be placed in subdirectories named after Maven names: orgId_artifactId_version"
        end
        Dir.mkdir("kit")
        File.open(File.join("kit", "README"), "w") do |file|
          file.puts "Build tool binaries are to be placed here"
        end

        `git add .`
        `git commit -m "gjp init #{Time.now}"`
        `git tag init`
      end
    end
  end
end
