# encoding: UTF-8

require 'find'

module Gjp
  # encapsulates a Gjp project directory
  class Project
    include Logger

    # list of possible statuses
    @@statuses = [:gathering, :dry_running]

    attr_accessor :full_path

    def initialize(path)      
      @full_path = Gjp::Project.find_project_dir(File.expand_path(path))
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
        if Dir.exists?(".git") == false
          `git init`
        end

        copy_from_template "file_lists", "."
        copy_from_template "src", "."
        copy_from_template "kit", "."

        `git add .`
        `git commit -m "Project initialized"`
  
        # automatically begin a gathering phase
        Project.new(".").gather
      end
    end

    # copies a file/dir from the template directory to the destination directory
    def self.copy_from_template(template_file, destination_dir)
      FileUtils.cp_r(File.join(File.dirname(__FILE__), "..", "template", template_file), destination_dir)
    end

    # starts a gathering phase, all files added to the project
    # will be added to packages (including kit)
    def gather
      from_directory do
        status = get_status
        if status == :gathering
          return false
        elsif status == :dry_running
          finish
        end

        set_status :gathering
        take_snapshot "Gathering started", :revertable
      end

      true
    end

    # starts a dry running phase: files added to the kit will
    # be added to packages, while sources will be reset at the
    # end
    def dry_run
      from_directory do
        status = get_status
        if status == :dry_running
          return false
        elsif status == :gathering
          finish
        end

        set_status :dry_running
        take_snapshot "Dry-run started", :revertable
      end

      true
    end

    # ends any phase that was previously started, 
    # generating file lists
    def finish
      from_directory do
        status = get_status
        if status == :gathering
          take_snapshot "Changes during gathering"

          update_changed_file_list("kit", "kit")
          update_changed_src_file_list(:input)
          take_snapshot "File list updates"

          set_status nil
          take_snapshot "Gathering finished", :revertable

          :gathering
        elsif status == :dry_running
          take_snapshot "Changes during dry-run"

          update_changed_file_list("kit", "kit")
          update_changed_src_file_list(:output)
          take_snapshot "File list updates"

          revert("src")
          take_snapshot "Sources reverted as before dry-run"

          set_status nil
          take_snapshot "Dry run finished", :revertable

          :dry_running
        end
      end
    end

    def update_changed_src_file_list(list_name)
      Dir.foreach("src") do |entry|
        if File.directory?(File.join(Dir.getwd, "src", entry)) and entry =~ /([^:\/]+:[^:]+:[^:]+)$/
          update_changed_file_list(File.join("src", entry), "#{$1}_#{list_name.to_s}")
        end
      end
    end

    def update_changed_file_list(directory, file_name)
      list_file = File.join("file_lists", file_name)
      tracked_files = if File.exists?(list_file)
        File.readlines(list_file)
      else
        []
      end

      new_tracked_files = (
        `git diff-tree --no-commit-id --name-only -r HEAD`.split("\n")
        .select { |file| file.start_with?(directory) }
        .map { |file|file[directory.length + 1, file.length]  }
        .concat(tracked_files)
        .sort
        .uniq
      )

      log.debug("writing file list for #{directory}: #{new_tracked_files.to_s}")

        
      File.open(list_file, "w+") do |file_list|
        new_tracked_files.each do |file|
          file_list.puts file
        end
      end
    end

    # adds the project's whole contents to git
    # if tag is given, commit is tagged
    def take_snapshot(message, revertability = :not_revertable)
      log.debug "committing with message: #{message}"

      `git rm -r --cached .`
      `git add .`
      `git commit -m "#{message}"`

      if revertability == :revertable
        latest_count = if latest_snapshot_name =~ /^gjp_revertable_snapshot_([0-9]+)$/
          $1
        else
          0
        end
        `git tag gjp_revertable_snapshot_#{$1.to_i + 1}`
      end
    end

    # returns the last snapshot git tag name
    def latest_snapshot_name
      `git describe --abbrev=0 --tags --match=gjp_revertable_snapshot_*`.strip
    end

    # reverts dir contents as commit_count commits ago
    def revert(dir)
      `git rm -rf --ignore-unmatch #{dir}`
      `git checkout -f #{latest_snapshot_name} -- #{dir}`

      `git clean -f -d #{dir}`
    end

    # returns a symbol with the current status
    # flag
    def get_status
      from_directory do
        @@statuses.each do |status|
          if File.exists?(status_file_name(status))
            return status
          end
        end
      end

      nil
    end

    # sets a project status flag. if status = nil,
    # clears all status flags
    def set_status(status)
      from_directory do
        @@statuses.each do |a_status|
          file_name = status_file_name(a_status)
          if File.exists?(file_name)
            File.delete(file_name)
          end

          if a_status == status
            FileUtils.touch(file_name)
          end
        end
      end
    end

    # returns a file name that represents a status
    def status_file_name(status)
      ".#{status.to_s}"
    end

    # runs a block from the project directory
    def from_directory
      Dir.chdir(@full_path) do
        yield
      end
    end
  end
end
