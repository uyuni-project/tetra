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

    # starts a gathering phase, all files added to the project
    # will be added to packages (including kit)
    def gather
      if get_status(:gathering)
        return :gathering
      elsif get_status(:dry_running)
        return :dry_running
      end

      set_status(:gathering)
      commit_all("gjp gather")

      :done
    end

    # adds the project's whole contents to git
    def commit_all(message)
      Dir.chdir(@dir) do
        Find.find(".") do |path|
          if path =~ /.gitignore$/
            puts "Deleting #{path} to preserve all files..."
            File.delete(path)
          end
        end

        `git add .`
        `git commit -m "#{message} #{Time.now}"`
      end
    end

    # gets a project status flag
    def get_status(status)
      Dir.chdir(@dir) do
        file_name = status_file_name(status)
        File.exists?(file_name)
      end
    end

    # sets a project status flag
    def set_status(status)
      Dir.chdir(@dir) do
        file_name = status_file_name(status)
        if File.exists?(file_name) == false
          FileUtils.touch(file_name)
        end
      end
    end

    # sets a project status flag
    def clear_status(status)
      Dir.chdir(@dir) do
        file_name = status_file_name(status)
        if File.exists?(file_name)
          File.delete(file_name)
        end
      end
    end

    def status_file_name(status)
      ".#{status.to_s}"
    end
  end
end
