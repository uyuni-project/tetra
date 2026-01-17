# frozen_string_literal: true

require "fileutils"

module Tetra
  # facade to git, currently implemented with calls to the git command
  class Git
    include Logging
    include ProcessRunner

    # inits a new git manager object pointing to the specified
    # directory
    def initialize(directory)
      @directory = directory
    end

    # inits a repo
    def init
      Dir.chdir(@directory) do
        if Dir.exist?(".git")
          fail GitAlreadyInitedError
        else
          git_cmd("init")
        end
      end
    end

    # returns the id of the most recent commit
    # that has the specified comment prefix in its message
    # returns nil if such commit does not exist
    def latest_id(comment_prefix)
      Dir.chdir(@directory) do
        result = git_cmd("rev-list", "--max-count=1", "--grep", comment_prefix, "--fixed-strings", "HEAD")
        result.strip unless result.empty?
      end
    end

    # returns the comment of the most recent commit
    # that has the specified comment prefix in its message
    # returns nil if such commit does not exist
    def latest_comment(comment_prefix)
      Dir.chdir(@directory) do
        id = latest_id(comment_prefix)
        git_cmd("log", "-1", "--format=%B", id) if id
      end
    end

    # adds all files in the specified directories,
    # removes all files not in the specified directories,
    # commits with message
    def commit_directories(directories, message)
      log.debug "committing with message: #{message}"

      Dir.chdir(@directory) do
        if directories.any?
          git_cmd("rm", "-r", "--cached", "--ignore-unmatch", *directories)
          git_cmd("add", *directories)
        end
        git_cmd_with_stdin(message, "commit", "--allow-empty", "-F", "-")
      end
    end

    # commits one single file
    def commit_file(path, message)
      Dir.chdir(@directory) do
        log.debug "committing path #{path} with message: #{message}"
        git_cmd("add", path)
        git_cmd_with_stdin(message, "commit", "--allow-empty", "-F", "-")
      end
    end

    # reverts multiple directories' contents as per specified id
    def revert_directories(directories, id)
      Dir.chdir(@directory) do
        directories.each do |directory|
          git_cmd("checkout", "-f", id, "--", directory)

          # Returns list of files relative to current dir
          files_in_commit = git_cmd("ls-tree", "--name-only", "-r", id, "--", directory).split("\n")
          files_in_head   = git_cmd("ls-tree", "--name-only", "-r", "HEAD", "--", directory).split("\n")
          files_added     = git_cmd("ls-files", "-o", "--", directory).split("\n")

          files_to_delete = (files_in_head - files_in_commit) + files_added

          files_to_delete.each do |file|
            FileUtils.rm_rf(file)
          end
        end
      end
    end

    # reverts the whole repo to the last commit while
    # leaving changes in the working directory
    def undo_last_commit
      Dir.chdir(@directory) do
        git_cmd("reset", "HEAD~")
      end
    end

    # renames git special files to 'disable' them
    def disable_special_files(path)
      Dir.chdir(File.join(@directory, path)) do
        # We look for .git directories or .gitignore files recursively
        Dir.glob("**/.git*", File::FNM_DOTMATCH).each do |file|
          next unless file.match?(/\.git(ignore)?$/)

          FileUtils.mv(file, "#{file}_disabled_by_tetra")
        end
      end
    end

    # 3-way merges the git file at path with the one in new_path
    # assuming they have a common ancestor at the specified id
    # returns the conflict count
    def merge_with_id(path, new_path, id)
      Dir.chdir(@directory) do
        content = git_cmd("show", "#{id}:#{path}")

        # Write the old version file manually using Ruby
        temp_old_version = "#{path}.old_version"
        File.write(temp_old_version, content)

        conflict_count = 0
        begin
          git_cmd("merge-file", path, temp_old_version, new_path,
                  "-L", "newly generated",
                  "-L", "previously generated",
                  "-L", "user edited")
        rescue ExecutionFailed => e
          if e.status > 0
            conflict_count = e.status
          else
            raise e
          end
        ensure
          # Clean up the temporary file
          File.delete(temp_old_version) if File.exist?(temp_old_version)
        end
        conflict_count
      end
    end

    # returns the list of files changed from since_id
    # including changes in the working tree and staging
    # area
    def changed_files(directory, id)
      Dir.chdir(@directory) do
        tracked_files = []
        begin
          tracked_files += git_cmd("diff-index", "--name-only", id, "--", directory).split
        rescue ExecutionFailed => e
          raise e if e.status != 1
        end

        untracked_files = git_cmd("ls-files", "--exclude-standard", "--others", "--", directory).split
        tracked_files + untracked_files
      end
    end

    # archives version id of directory in destination_path
    def archive(directory, id, destination_path)
      Dir.chdir(@directory) do
        FileUtils.mkdir_p(File.dirname(destination_path))

        log.debug "archiving #{directory} from #{id} to #{destination_path}"

        # This streams stdout from git directly to stdin of xz without loading
        # data into Ruby memory (which could be big).
        git_command = ["git", "archive", "--format=tar", id, "--", directory]
        xz_command  = ["xz", "-9e"]

        statuses = Open3.pipeline(git_command, xz_command, out: destination_path)

        unless statuses.all?(&:success?)
          fail ExecutionFailed.new(
            "git archive pipeline failed (exit codes: #{statuses.map(&:exitstatus)})",
            statuses.last.exitstatus
          )
        end
      end
      destination_path
    end

    # generates patch files to changes to directory in destination_path
    # since from_id
    def format_patch(directory, from_id, destination_path)
      Dir.chdir(@directory) do
        git_cmd("format-patch", "-o", destination_path, "--no-numbered", from_id, "--", directory).split
      end
    end

    private

    # Automatically passes "git" as the first argument in an Array.
    def git_cmd(*args)
      run(["git"] + args)
    end

    def git_cmd_with_stdin(stdin_data, *args)
      run(["git"] + args, false, stdin_data)
    end
  end

  class GitAlreadyInitedError < StandardError
  end
end
