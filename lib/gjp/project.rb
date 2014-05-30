# encoding: UTF-8

module Gjp
  # encapsulates a Gjp project directory
  class Project
    include Logging

    attr_accessor :full_path
    attr_accessor :git

    def initialize(path)
      @full_path = Gjp::Project.find_project_dir(File.expand_path(path))
      @git = Gjp::Git.new(@full_path)
    end

    def name
      File.basename(@full_path)
    end

    def version
      latest_tag_count(:dry_run_finished)
    end

    # finds the project directory up in the tree, like git does
    def self.find_project_dir(starting_dir)
      result = starting_dir
      while is_project(result) == false && result != "/"
        result = File.expand_path("..", result)
      end

      fail NoProjectDirectoryError.new(starting_dir) if result == "/"

      result
    end

    # returns true if the specified directory is a valid gjp project
    def self.is_project(dir)
      File.directory?(File.join(dir, "src")) &&
      File.directory?(File.join(dir, "kit")) &&
      File.directory?(File.join(dir, ".git"))
    end

    # returns the package name corresponding to the specified dir, if any
    # raises NoPackageDirectoryError if dir is not a (sub)directory of a package
    def get_package_name(dir)
      dir_path = Pathname.new(File.expand_path(dir)).relative_path_from(Pathname.new(@full_path))
      components = dir_path.to_s.split(File::SEPARATOR)
      if components.count >= 2 &&
       components.first == "src" &&
       Dir.exist?(File.join(@full_path, components[0], components[1]))
        components[1]
     else
       fail NoPackageDirectoryError
     end
    rescue ArgumentError, NoProjectDirectoryError
      raise NoPackageDirectoryError.new(dir)
    end

    # inits a new project directory structure
    def self.init(dir)
      Dir.chdir(dir) do
        Gjp::Git.new(".").init

        FileUtils.mkdir_p "src"
        FileUtils.mkdir_p "kit"

        # populate the project with templates and take a snapshot
        project = Project.new(".")

        template_manager = Gjp::TemplateManager.new
        template_manager.copy "output", "."
        template_manager.copy "kit", "."
        template_manager.copy "src", "."
        template_manager.copy "gitignore", ".gitignore"

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
    # if abort is true, reverts the whole directory
    # if abort is false, reverts sources and updates output file lists
    def finish(abort)
      if is_dry_running
        if abort
          @git.revert_whole_directory(".", latest_tag(:dry_run_started))
          @git.delete_tag(latest_tag(:dry_run_started))
        else
          take_snapshot "Changes during dry-run", :dry_run_changed

          @git.revert_whole_directory("src", latest_tag(:dry_run_started))

          take_snapshot "Dry run finished", :dry_run_finished
        end
        return true
      end
      false
    end

    # takes a revertable snapshot of this project
    def take_snapshot(message, tag_prefix = nil, tag_message = nil)
      tag = (
        if tag_prefix
          "#{tag_prefix}_#{latest_tag_count(tag_prefix) + 1}"
        else
          nil
        end
      )

      @git.commit_whole_directory(message, tag, tag_message)
    end

    # replaces content in path with new_content, takes a snapshot using
    # snapshot_message and tag_prefix and 3-way merges new and old content
    # with a previous snapshotted file same path tag_prefix, if it exists.
    # returns the number of conflicts
    def merge_new_content(new_content, path, snapshot_message, tag_prefix)
      from_directory do
        log.debug "merging new content to #{path} with prefix #{tag_prefix}"
        already_existing = File.exist? path
        previous_tag = latest_tag(tag_prefix)

        if already_existing
          log.debug "moving #{path} to #{path}.gjp_user_edited"
          File.rename path, "#{path}.gjp_user_edited"
        end

        File.open(path, "w") { |io| io.write(new_content) }
        log.debug "taking snapshot with new content: #{snapshot_message}"
        take_snapshot(snapshot_message, tag_prefix)

        if already_existing
          if previous_tag == ""
            previous_tag = latest_tag(tag_prefix)
            log.debug "there was no tag with prefix #{tag_prefix} before snapshot"
            log.debug "defaulting to #{previous_tag} after snapshot"
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

    # returns the latest dry run start directory
    def latest_dry_run_directory
      @git.get_message(latest_tag(:dry_run_started))
    end

    # returns a list of files produced during dry-runs in a certain package
    def get_produced_files(package)
      dry_run_count = latest_tag_count(:dry_run_changed)
      log.debug "Getting produced files from #{dry_run_count} dry runs"
      if dry_run_count >= 1
        package_dir = File.join("src", package)
        (1..dry_run_count).map do |i|
          @git.changed_files_between("dry_run_started_#{i}", "dry_run_changed_#{i}", package_dir)
        end
          .flatten
          .uniq
          .sort
          .map { |file| Pathname.new(file).relative_path_from(Pathname.new(package_dir)).to_s }
      else
        []
      end
    end

    # moves any .jar from src/ to kit/ and links it back
    def purge_jars
      from_directory do
        result = []
        Find.find("src") do |file|
          if file =~ /.jar$/ && !File.symlink?(file)
            new_location = File.join("kit", "jars", Pathname.new(file).split[1])
            FileUtils.mv(file, new_location)

            link_target = Pathname.new(new_location)
              .relative_path_from(Pathname.new(file).split.first)
              .to_s

            File.symlink(link_target, file)
            result << [file, new_location]
          end
        end

        result
      end
    end
  end

  # current directory is not a gjp project
  class NoProjectDirectoryError < StandardError
    attr_reader :directory

    def initialize(directory)
      @directory = directory
    end
  end

  # current directory is not a gjp package directory
  class NoPackageDirectoryError < StandardError
    attr_reader :directory

    def initialize(directory)
      @directory = directory
    end
  end
end
