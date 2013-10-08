# encoding: UTF-8

require 'find'

module Gjp
  # encapsulates a Gjp project directory
  class Project
    include Logger

    attr_accessor :full_path

    def initialize(path)      
      @full_path = Gjp::Project.find_project_dir(File.expand_path(path))
      @git = Gjp::Git.new
    end

    # finds the project directory up in the tree, like git does
    def self.find_project_dir(starting_dir)
      result = starting_dir
      while is_project(result) == false and result != "/"
        result = File.expand_path("..", result)
      end

      raise NotGjpDirectoryException if result == "/"

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
        Gjp::Git.init

        Dir.mkdir "src"
        Dir.mkdir "kit"

        # populate the project with templates and take a snapshot
        project = Project.new(".")

        template_manager = Gjp::TemplateManager.new
        template_manager.copy "archives", "."
        template_manager.copy "file_lists", "."
        template_manager.copy "kit", "."
        template_manager.copy "specs", "."
        template_manager.copy "src", "."

        project.take_snapshot "Template files added", :init
      end
    end

    # starts a dry running phase: files added to kit/ will be added
    # to the kit package, src/ will be reset at the current state
    # when finished
    def dry_run
      from_directory do
        if is_dry_running
          return false
        end

        take_snapshot "Dry-run started", :dry_run_started
      end

      true
    end

    # returns true iff we are currently dry-running
    def is_dry_running
      latest_tag_count(:dry_run_started) > latest_tag_count(:dry_run_finished)
    end

    # ends a dry-run.
    # if failed is true, reverts the whole directory
    # if failed is false, reverts sources and updates output file lists
    def finish(failed)
      from_directory do
        if is_dry_running
          if failed
            @git.revert_whole_directory(".", latest_tag(:dry_run_started))
          else
            take_snapshot "Changes during dry-run"

            update_output_file_lists
            take_snapshot "File list updates"

            @git.revert_whole_directory("src", latest_tag(:dry_run_started))
            take_snapshot "Sources reverted as before dry-run"

            take_snapshot "Dry run finished", :dry_run_finished
          end
          return true
        end
      end
      false
    end

    # updates files that contain lists of the output files produced by
    # the build of each package
    def update_output_file_lists
      Dir.foreach("src") do |entry|
        if File.directory?(File.join(Dir.getwd, "src", entry)) and entry != "." and entry != ".."
          directory = File.join("src", entry)
          file_name = "#{entry}_output"
          list_file = File.join("file_lists", file_name)
          tracked_files = if File.exists?(list_file)
            File.readlines(list_file).map { |line| line.strip }
          else
            []
          end

          new_tracked_files = (
            @git.changed_files_since(latest_tag(:dry_run_started))
              .select { |file| file.start_with?(directory) }
              .map { |file|file[directory.length + 1, file.length] }
              .concat(tracked_files)
              .uniq
              .sort
          )

          log.debug("writing file list for #{directory}: #{new_tracked_files.to_s}")

          File.open(list_file, "w+") do |file_list|
            new_tracked_files.each do |file|
              file_list.puts file
            end
          end
        end
      end
    end

    # takes a revertable snapshot of this project
    def take_snapshot(message, prefix = nil)
      tag = if prefix
        "#{prefix}_#{latest_tag_count(prefix) + 1}"
      else
        nil
      end

      @git.commit_whole_directory(message, tag)
    end

    # returns the last tag of its type corresponding to a
    # gjp snapshot
    def latest_tag(tag_type)
      "#{tag_type}_#{latest_tag_count(tag_type)}"
    end

    # returns the last tag count of its type corresponding
    # to a gjp snapshot
    def latest_tag_count(tag_type)
      @git.get_tag_maximum_suffix(tag_type)
    end

    # runs a block from the project directory or a subdirectory
    def from_directory(subdirectory = "")
      Dir.chdir(File.join(@full_path, subdirectory)) do
        yield
      end
    end

    # helpers for ERB

    def name
      File.basename(@full_path)
    end

    def version
      latest_tag_count(:dry_run_finished)
    end

    def get_binding
      binding
    end
  end

  class NotGjpDirectoryException < Exception
  end
end
