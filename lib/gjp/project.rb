# encoding: UTF-8

require 'find'

module Gjp
  # encapsulates a Gjp project directory
  class Project
    def log
      Gjp.logger
    end

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
        `git commit -m "gjp init"`
        `git tag init`
      end
    end

    # starts a gathering phase, all files added to the project
    # will be added to packages (including kit)
    def gather
      Dir.chdir(@dir) do
        if get_status(:gathering)
          return :gathering
        elsif get_status(:dry_running)
          return :dry_running
        end

        set_status(:gathering)
        commit_all("gjp gather")
      end

      :done
    end

    # starts a dry running phase: files added to the kit will
    # be added to packages, while sources will be reset at the
    # end
    def dry_run
      Dir.chdir(@dir) do
        if get_status(:gathering)
          return :gathering
        elsif get_status(:dry_running)
          return :dry_running
        end

        set_status(:dry_running)
        commit_all("gjp dry-run")
      end

      :done
    end

    # ends any phase that was previously started, 
    # generating file lists
    def finish
      Dir.chdir(@dir) do
        if get_status(:gathering)
          commit_all("gjp finish (gathering)")

          write_file_list("kit")
          Dir.foreach("src") do |entry|
            if File.directory?(File.join(Dir.getwd, "src", entry)) and entry =~ /[^_]+_[^_]+_[^_]+$/
              write_file_list(File.join("src", entry))
            end
          end

          commit_all("file lists updated")

          clear_status(:gathering)

          :gathering
        elsif get_status(:dry_running)
          revert("src")
          commit_all("gjp finish (dry-running)")

          write_file_list("kit")

          commit_all("file lists updated")

          clear_status(:dry_running)

          :dry_running
        end
      end
    end

    def write_file_list(directory)
      list_path = "#{directory}/gjp_file_list"

      existing_files = if File.exists?(list_path)
        File.readlines(list_path)
      else
        []
      end

      files = (
        `git diff-tree --no-commit-id --name-only -r HEAD`.split("\n")
        .select { |file| file.start_with?(directory) }
        .map { |file|file[directory.length + 1, file.length]  }
        .concat(existing_files)
        .sort
        .uniq
      )

      log.debug("writing file list for #{directory}: #{files.to_s}")

        
      File.open("#{directory}/gjp_file_list", "w+") do |file_list|
        files.each do |file|
          file_list.puts file
        end
      end
    end

    # adds the project's whole contents to git
    def commit_all(message)
      Find.find(".") do |path|
        if path =~ /.gitignore$/
          puts "Deleting #{path} to preserve all files..."
          File.delete(path)
        end
      end

      log.debug "committing with message: #{message}"

      `git add .`
      `git commit -m "#{message}"`
    end

    def revert(dir)
      `git checkout -f HEAD -- #{dir}`
      `git clean -f -d #{dir}`
    end

    # gets a project status flag
    def get_status(status)
      file_name = status_file_name(status)
      File.exists?(file_name)
    end

    # sets a project status flag
    def set_status(status)
      file_name = status_file_name(status)
      if File.exists?(file_name) == false
        FileUtils.touch(file_name)
      end
    end

    # sets a project status flag
    def clear_status(status)
      file_name = status_file_name(status)
      if File.exists?(file_name)
        File.delete(file_name)
      end
    end

    def status_file_name(status)
      ".#{status.to_s}"
    end
  end
end
