# encoding: UTF-8

module Tetra
  # encapsulates a Tetra project directory
  class Project
    include Logging

    attr_reader :full_path

    def initialize(path)
      @full_path = Tetra::Project.find_project_dir(File.expand_path(path))
      @git = Tetra::Git.new(@full_path)
    end

    def name
      File.basename(@full_path)
    end

    def version
      latest_tag_count(:dry_run_finished)
    end

    def packages_dir
      "packages"
    end

    # finds the project directory up in the tree, like git does
    def self.find_project_dir(starting_dir)
      result = starting_dir
      while project?(result) == false && result != "/"
        result = File.expand_path("..", result)
      end

      fail NoProjectDirectoryError, starting_dir if result == "/"

      result
    end

    # returns true if the specified directory is a valid tetra project
    def self.project?(dir)
      File.directory?(File.join(dir, "src")) &&
        File.directory?(File.join(dir, "kit")) &&
        File.directory?(File.join(dir, ".git"))
    end

    # inits a new project directory structure
    def self.init(dir)
      Dir.chdir(dir) do
        Tetra::Git.new(".").init

        FileUtils.mkdir_p("src")
        FileUtils.mkdir_p("kit")

        # populate the project with templates and take a snapshot
        project = Project.new(".")

        template_path = File.join(File.dirname(__FILE__), "..", "template")

        templates = {
          "kit" => ".",
          "packages" => ".",
          "src" => ".",
          "gitignore" => ".gitignore"
        }

        templates.each do |source, destination|
          FileUtils.cp_r(File.join(template_path, source), destination)
        end

        project.take_snapshot("Template files added", :init)
      end
    end

    # starts a dry running phase: files added to kit/ will be added
    # to the kit package, src/ will be reset at the current state
    # when finished
    def dry_run
      return false if dry_running?

      current_directory = Pathname.new(Dir.pwd).relative_path_from(Pathname.new(@full_path))

      take_snapshot("Dry-run started", :dry_run_started, current_directory)
      true
    end

    # returns true iff we are currently dry-running
    def dry_running?
      latest_tag_count(:dry_run_started) > latest_tag_count(:dry_run_finished)
    end

    # ends a dry-run assuming a successful build
    # reverts sources and updates output file lists
    def finish
      if dry_running?
        take_snapshot("Changes during dry-run", :dry_run_changed)

        @git.revert_whole_directory("src", latest_tag(:dry_run_started))

        take_snapshot("Dry run finished", :dry_run_finished)
        return true
      end
      false
    end

    # ends a dry-run assuming the built went wrong
    # reverts the whole project directory
    def abort
      if dry_running?
        @git.revert_whole_directory(".", latest_tag(:dry_run_started))
        @git.delete_tag(latest_tag(:dry_run_started))
        return true
      end
      false
    end

    # takes a revertable snapshot of this project
    def take_snapshot(message, tag_prefix, tag_message = nil)
      # rename all .gitignore files by default as
      # they prevent snapshotting
      from_directory("src") do
        Find.find(".") do |file|
          next unless file =~ /\.gitignore$/

          FileUtils.mv(file, "#{file}_disabled_by_tetra")
        end
      end

      @git.commit_whole_directory(message, next_tag(tag_prefix), tag_message)
    end

    # replaces content in path with new_content, takes a snapshot using
    # snapshot_message and tag_prefix and 3-way merges new and old content
    # with a previous snapshotted file same path tag_prefix, if it exists.
    # returns the number of conflicts
    def merge_new_content(new_content, path, snapshot_message, tag_prefix)
      from_directory do
        log.debug "merging new content to #{path} with prefix #{tag_prefix}"
        already_existing = File.exist?(path)

        if already_existing
          if latest_tag_count(tag_prefix) == 0
            log.debug "saving untagged version"
            @git.commit_file(path, snapshot_message, next_tag(tag_prefix))
          end
          log.debug "moving #{path} to #{path}.tetra_user_edited"
          File.rename path, "#{path}.tetra_user_edited"
        end

        previous_tag = latest_tag(tag_prefix)

        File.open(path, "w") { |io| io.write(new_content) }
        log.debug "taking snapshot with new content: #{snapshot_message}"
        @git.commit_file(path, snapshot_message, next_tag(tag_prefix))

        if already_existing
          # 3-way merge
          conflict_count = @git.merge_with_tag("#{path}", "#{path}.tetra_user_edited", previous_tag)
          File.delete "#{path}.tetra_user_edited"
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

    # returns the next tag for a given tag prefix
    def next_tag(prefix)
      "#{prefix}_#{latest_tag_count(prefix) + 1}"
    end

    # runs a block from the project directory or a subdirectory
    def from_directory(subdirectory = "")
      Dir.chdir(File.join(@full_path, subdirectory)) do
        yield
      end
    end

    # returns the latest dry run start directory
    def latest_dry_run_directory
      @git.get_message(latest_tag(:dry_run_started))
    end

    # returns a list of files produced during dry-runs
    def produced_files
      dry_run_count = latest_tag_count(:dry_run_changed)
      log.debug "Getting produced files from #{dry_run_count} dry runs"
      if dry_run_count >= 1
        (1..dry_run_count).map do |i|
          @git.changed_files_between("dry_run_started_#{i}", "dry_run_changed_#{i}", "src")
        end
          .flatten
          .uniq
          .sort
          .map { |file| Pathname.new(file).relative_path_from(Pathname.new("src")).to_s }
      else
        []
      end
    end

    # moves any .jar from src/ to kit/ and links it back
    def purge_jars
      from_directory do
        result = []
        Find.find("src") do |file|
          next unless file =~ /.jar$/ && !File.symlink?(file)

          new_location = File.join("kit", "jars", Pathname.new(file).split[1])
          FileUtils.mv(file, new_location)

          link_target = Pathname.new(new_location)
                        .relative_path_from(Pathname.new(file).split.first)
                        .to_s

          File.symlink(link_target, file)
          result << [file, new_location]
        end

        result
      end
    end
  end

  # current directory is not a tetra project
  class NoProjectDirectoryError < StandardError
    attr_reader :directory

    def initialize(directory)
      @directory = directory
    end
  end
end
