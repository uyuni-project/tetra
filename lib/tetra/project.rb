# encoding: UTF-8

module Tetra
  # encapsulates a Tetra project directory
  class Project
    include Logging

    # path of the project template files
    TEMPLATE_PATH = File.join(File.dirname(__FILE__), "..", "template")

    attr_reader :full_path

    def initialize(path)
      @full_path = Tetra::Project.find_project_dir(File.expand_path(path))
      @git = Tetra::Git.new(@full_path)
    end

    def name
      File.basename(@full_path)
    end

    def version
      @git.latest_id("tetra: dry-run-finished")
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
    def self.init(dir, include_bundled_software = true)
      Dir.chdir(dir) do
        Tetra::Git.new(".").init

        FileUtils.mkdir_p("src")
        FileUtils.mkdir_p("kit")

        # populate the project with templates and commit it
        project = Project.new(".")

        project.template_files(include_bundled_software).each do |source, destination|
          FileUtils.cp_r(File.join(TEMPLATE_PATH, source), destination)
        end

        project.commit_whole_directory(".", "Template files added")
      end
    end

    # returns a hash that maps filenames that should be copied from TEMPLATE_PATH
    # to the value directory
    def template_files(include_bundled_software)
      result = {
        "kit" => ".",
        "packages" => ".",
        "src" => ".",
        "gitignore" => ".gitignore"
      }

      if include_bundled_software
        Dir.chdir(TEMPLATE_PATH) do
          Dir.glob(File.join("bundled", "*")).each do |file|
            result[file] = "kit"
          end
        end
      end

      result
    end

    # checks whether there were edits to src/
    # since last mark
    def src_patched?
      from_directory do
        latest_id = @git.latest_id("tetra: sources-")
        if latest_id
          @git.changed_files("src", latest_id).any?
        else
          false
        end
      end
    end

    # starts a dry running phase: files added to kit/ will be added
    # to the kit package, src/ will be reset at the current state
    # when finished
    def dry_run
      current_directory = Pathname.new(Dir.pwd).relative_path_from(Pathname.new(@full_path))

      commit_whole_directory(".", "Dry-run started\n", "tetra: dry-run-started: #{current_directory}")
    end

    # returns true iff we are currently dry-running
    def dry_running?
      latest_comment = @git.latest_comment("tetra: dry-run-")
      !latest_comment.nil? && !(latest_comment =~ /tetra: dry-run-finished/)
    end

    # ends a dry-run assuming a successful build
    # reverts sources and updates output file lists
    def finish
      commit_whole_directory(".", "Changes during dry-run\n", "tetra: dry-run-changed")

      @git.revert_whole_directory("src", @git.latest_id("tetra: dry-run-started"))

      # if this is the first dry-run, mark sources as tarball
      comments = ["Dry run finished\n", "tetra: dry-run-finished"]
      if @git.latest_id("tetra: dry-run-finished").nil?
        comments << "tetra: sources-tarball"
      end

      commit_whole_directory(".", *comments)
    end

    # ends a dry-run assuming the build went wrong
    # reverts the whole project directory
    def abort
      @git.revert_whole_directory(".", @git.latest_id("tetra: dry-run-started"))
      @git.undo_last_commit
    end

    # commits all files in the directory
    def commit_whole_directory(directory, *comments)
      # rename all .gitignore files that might have slipped in
      from_directory("src") do
        Find.find(".") do |file|
          next unless file =~ /\.gitignore$/

          FileUtils.mv(file, "#{file}_disabled_by_tetra")
        end
      end

      @git.commit_whole_directory(directory, comments.join("\n"))
    end

    # commits files in the src/ dir as a patch or tarball update
    def commit_sources(as_patch, message)
      from_directory do
        comments = ["#{message}\n"]
        comments << (as_patch ? "tetra: sources-patch" : "tetra: sources-tarball")
        commit_whole_directory("src", comments)
      end
    end

    # replaces content in path with new_content, commits using
    # comment and 3-way merges new and old content with the previous
    # version of file of the same kind, if it exists.
    # returns the number of conflicts
    def merge_new_content(new_content, path, comment, kind)
      from_directory do
        log.debug "merging new content to #{path} of kind #{kind}"
        already_existing = File.exist?(path)

        generated_comment = "tetra: generated-#{kind}"
        whole_comment = [comment, generated_comment].join("\n\n")

        if already_existing
          unless @git.latest_id(generated_comment)
            log.debug "committing new file"
            @git.commit_file(path, whole_comment)
          end
          log.debug "moving #{path} to #{path}.tetra_user_edited"
          File.rename(path, "#{path}.tetra_user_edited")
        end

        previous_id = @git.latest_id(generated_comment)

        File.open(path, "w") { |io| io.write(new_content) }
        log.debug "committing new content: #{comment}"
        @git.commit_file(path, whole_comment)

        if already_existing
          # 3-way merge
          conflict_count = @git.merge_with_id("#{path}", "#{path}.tetra_user_edited", previous_id)
          File.delete("#{path}.tetra_user_edited")
          return conflict_count
        end
        return 0
      end
    end

    # runs a block from the project directory or a subdirectory
    def from_directory(subdirectory = "")
      Dir.chdir(File.join(@full_path, subdirectory)) do
        yield
      end
    end

    # returns the latest dry run start directory
    def latest_dry_run_directory
      @git.latest_comment("tetra: dry-run-started")[/tetra: dry-run-started: (.*)$/, 1]
    end

    # returns a list of files produced during the last dry-run
    def produced_files
      start_id = @git.latest_id("tetra: dry-run-started")
      end_id = @git.latest_id("tetra: dry-run-changed")
      if !start_id.nil? && !end_id.nil?
        @git.changed_files_between(start_id, end_id, "src")
          .sort
          .map { |file| Pathname.new(file).relative_path_from(Pathname.new("src")).to_s }
      else
        []
      end
    end

    # archives a tarball of src/ in packages/
    # the latest commit marked as tarball is taken as the version
    def archive_sources
      from_directory do
        id = @git.latest_id("tetra: sources-tarball")
        destination_path = File.join(full_path, packages_dir, name, "#{name}.tar.xz")
        @git.archive("src", id, destination_path)
      end
    end

    # archives a tarball of kit/ in packages/
    # the latest commit marked as dry-run-finished is taken as the version
    def archive_kit
      from_directory do
        id = @git.latest_id("tetra: dry-run-finished")
        destination_path = File.join(full_path, packages_dir, "#{name}-kit", "#{name}-kit.tar.xz")
        @git.archive("kit", id, destination_path)
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
