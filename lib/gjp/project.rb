# encoding: UTF-8

require 'find'

module Gjp
  # encapsulates a Gjp project directory
  class Project
    def log
      Gjp.logger
    end

    def initialize(dir)      
      @dir = Gjp::Project.find_project_dir(File.expand_path(dir))
    end

    # finds the project directory up in the tree, like git does
    def self.find_project_dir(starting_dir)
      result = starting_dir
      while is_project(result) == false and result != "/"
        result = File.expand_path("..", result)
      end

      raise ArgumentError, "This is not a gjp project directory" if result == "/"

      result
    end

    # returns true if the specified directory is a valid gjp project
    def self.is_project(dir)
      File.directory?(File.join(dir, "src")) and
      File.directory?(File.join(dir, "kit")) and
      File.directory?(File.join(dir, ".git"))
    end

    # inits a new project directory structure
    def self.init(dir)
      Dir.chdir(dir) do
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
        `git commit -m "Project initialized"`
        `git tag init`
      end
    end

    # starts a gathering phase, all files added to the project
    # will be added to packages (including kit)
    def gather
      from_directory do
        if get_status(:gathering)
          return :gathering
        elsif get_status(:dry_running)
          return :dry_running
        end

        set_status(:gathering)
        commit_all("Gathering started")
      end

      :done
    end

    # starts a dry running phase: files added to the kit will
    # be added to packages, while sources will be reset at the
    # end
    def dry_run
      from_directory do
        if get_status(:gathering)
          return :gathering
        elsif get_status(:dry_running)
          return :dry_running
        end

        set_status(:dry_running)
        commit_all("Dry-run started")
      end

      :done
    end

    # ends any phase that was previously started, 
    # generating file lists
    def finish
      from_directory do
        if get_status(:gathering)
          commit_all("Changes during gathering")

          update_changed_file_list("kit", "gjp_kit_file_list")
          update_changed_src_file_list(:file_list)
          commit_all("File list updates")

          clear_status(:gathering)
          commit_all("Gathering finished")

          :gathering
        elsif get_status(:dry_running)
          commit_all("Changes during dry-run")

          update_changed_file_list("kit", "gjp_kit_file_list")
          update_changed_src_file_list(:produced_file_list)
          commit_all("File list updates")

          revert("src", 2)
          commit_all("Sources reverted as before dry-run")

          clear_status(:dry_running)
          commit_all("Dry run finished")

          :dry_running
        end
      end
    end

    def update_changed_src_file_list(list_name)
      Dir.foreach("src") do |entry|
        if File.directory?(File.join(Dir.getwd, "src", entry)) and entry =~ /([^_\/]+_[^_]+_[^_]+)$/
          update_changed_file_list(File.join("src", entry), "gjp_#{$1}_#{list_name.to_s}")
        end
      end
    end

    def update_changed_file_list(directory, list_file)
      existing_files = if File.exists?(list_file)
        File.readlines(list_file)
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

        
      File.open(list_file, "w+") do |file_list|
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

      `git rm -r --cached .`
      `git add .`
      `git commit -m "#{message}"`
    end

    # reverts dir contents as commit_count commits ago
    def revert(dir, commit_count)
      `git rm -rf --ignore-unmatch #{dir}`
      `git checkout -f HEAD~#{commit_count} -- #{dir}`

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

    # runs a block from the project directory
    def from_directory
      Dir.chdir(@dir) do
        yield
      end
    end
  end
end
