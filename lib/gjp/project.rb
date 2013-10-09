# encoding: UTF-8

require 'find'

module Gjp
  # encapsulates a Gjp project directory
  class Project
    include Logger

    attr_accessor :full_path

    def initialize(path)      
      @full_path = Gjp::Project.find_project_dir(File.expand_path(path))
      @git = Gjp::Git.new(@full_path)
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
        Gjp::Git.new(".").init

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
        template_manager.copy ".gitignore", ".gitignore"

        project.take_snapshot "Template files added", :init
      end
    end

    # starts a dry running phase: files added to kit/ will be added
    # to the kit package, src/ will be reset at the current state
    # when finished
    def dry_run
      if is_dry_running
        return false
      end

      current_directory = Pathname.new(Dir.pwd).relative_path_from Pathname.new(@full_path)

      take_snapshot("Dry-run started", :dry_run_started, current_directory)
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
      if is_dry_running
        if failed
          @git.revert_whole_directory(".", latest_tag(:dry_run_started))
          @git.delete_tag(latest_tag(:dry_run_started))
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
      false
    end

    # updates files that contain lists of the output files produced by
    # the build of each package
    def update_output_file_lists
      each_package_directory do |directory|
        files = (
          @git.changed_files_since(latest_tag(:dry_run_started))
            .select { |file| file.start_with?(directory) }
            .map { |file|file[directory.length + 1, file.length] }
            .sort
        )

        log.debug("writing file list for #{directory}: #{files.to_s}")

        list_path = File.join("file_lists", "#{Pathname.new(directory).basename}_output")
        File.open(list_path, "w+") do |file_list|
          files.each do |file|
            file_list.puts file
          end
        end
      end
    end

    # takes a revertable snapshot of this project
    def take_snapshot(message, tag_prefix = nil, tag_message = nil)
      tag = if tag_prefix
        "#{tag_prefix}_#{latest_tag_count(tag_prefix) + 1}"
      else
        nil
      end

      @git.commit_whole_directory(message, tag, tag_message)
    end

    # replaces content in path with new_content, takes a snapshot using
    # snapshot_message and tag_prefix and 3-way merges new and old content
    # with a previous snapshotted file same path tag_prefix, if it exists.
    # returns the number of conflicts
    def merge_new_content(new_content, path, snapshot_message, tag_prefix)
      from_directory do
        already_existing = File.exist? path
        previous_tag = latest_tag(tag_prefix)

        if already_existing
          File.rename path, "#{path}.gjp_user_edited"
        end

        File.open(path, "w") { |io| io.write(new_content) }
        take_snapshot(snapshot_message, tag_prefix)

        if already_existing
          if previous_tag == ""
            previous_tag = latest_tag(tag_prefix)
          end

          # 3-way merge
          conflict_count = @git.merge_with_tag("#{path}", "#{path}.gjp_user_edited", previous_tag)
          File.delete "#{path}.gjp_user_edited"
          return conflict_count
        end
        return 0
      end
    end

    # returns the tag with maximum count for a given tag prefix
    def latest_tag(prefix)
      "#{prefix}_#{latest_tag_count(prefix)}"
    end

    # returns the maximum tag count for a given tag prefix
    def latest_tag_count(prefix)
      @git.get_tag_maximum_suffix(prefix)
    end

    # runs a block from the project directory or a subdirectory
    def from_directory(subdirectory = "")
      Dir.chdir(File.join(@full_path, subdirectory)) do
        yield
      end
    end

    # runs a block for each package directory in src/
    def each_package_directory
      from_directory do
        Dir.foreach("src") do |entry|
          if File.directory?(File.join(Dir.getwd, "src", entry)) and entry != "." and entry != ".."
            directory = File.join("src", entry)
            yield directory
          end
        end
      end
    end

    # returns the latest dry run start directory
    def latest_dry_run_directory
      @git.get_message(latest_tag(:dry_run_started))
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
