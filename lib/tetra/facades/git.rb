# encoding: UTF-8

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
        if Dir.exist?(".git") == false
          run("git init")
        else
          fail GitAlreadyInitedError
        end
      end
    end

    # returns the id of the most recent commit
    # that has the specified comment prefix in its message
    # returns nil if such commit does not exist
    def latest_id(comment_prefix)
      Dir.chdir(@directory) do
        result = run("git rev-list --max-count=1 --grep=\"#{comment_prefix}\" --fixed-strings HEAD")
        result.strip if result != ""
      end
    end

    # returns the comment of the most recent commit
    # that has the specified comment prefix in its message
    # returns nil if such commit does not exist
    def latest_comment(comment_prefix)
      Dir.chdir(@directory) do
        id = latest_id(comment_prefix)
        run("git rev-list --max-count=1 --format=%B #{id}") unless id.nil?
      end
    end

    # adds all files in the current directory,
    # removes all files not in the current directory,
    # commits with message
    def commit_whole_directory(directory, message)
      Dir.chdir(@directory) do
        log.debug "committing with message: #{message}"

        run("git rm -r --cached --ignore-unmatch #{directory}")
        run("git add #{directory}")
        run("git commit --allow-empty -F -", false, message)
      end
    end

    # commits one single file
    def commit_file(path, message)
      Dir.chdir(@directory) do
        log.debug "committing path #{path} with message: #{message}"
        run("git add #{path}")
        run("git commit --allow-empty -F -", false, message)
      end
    end

    # reverts path contents as per specified id
    def revert_whole_directory(path, id)
      Dir.chdir(@directory) do
        # reverts added and modified files, both in index and working tree
        run("git checkout -f #{id} -- #{path}")

        # compute the list of deleted files
        files_in_commit = run("git ls-tree --name-only -r #{id} -- #{path}").split("\n")
        files_in_head = run("git ls-tree --name-only -r HEAD -- #{path}").split("\n")
        files_added_after_head = run("git ls-files -o -- #{path}").split("\n")
        files_to_delete = files_in_head - files_in_commit + files_added_after_head

        files_to_delete.each do |file|
          FileUtils.rm_rf(file)
        end
      end
    end

    # reverts the whole repo to the last commit while
    # leaving changes in the working directory
    def undo_last_commit
      Dir.chdir(@directory) do
        run("git reset HEAD~")
      end
    end

    # 3-way merges the git file at path with the one in new_path
    # assuming they have a common ancestor at the specified id
    # returns the conflict count
    def merge_with_id(path, new_path, id)
      Dir.chdir(@directory) do
        run("git show #{id}:#{path} > #{path}.old_version")

        conflict_count = 0
        begin
          run("git merge-file #{path} #{path}.old_version #{new_path} \
                -L \"newly generated\" \
                -L \"previously generated\" \
                -L \"user edited\"")
        rescue ExecutionFailed => e
          if e.status > 0
            conflict_count = e.status
          else
            raise e
          end
        end
        File.delete("#{path}.old_version")
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
          tracked_files += run("git diff-index --name-only #{id} -- #{directory}").split
        rescue ExecutionFailed => e
          raise e if e.status != 1 # status 1 is normal
        end

        untracked_files = run("git ls-files --exclude-standard --others -- #{directory}").split
        tracked_files + untracked_files
      end
    end

    # archives version id of directory in destination_path
    def archive(directory, id, destination_path)
      Dir.chdir(@directory) do
        FileUtils.mkdir_p(File.dirname(destination_path))
        run("git archive --format=tar #{id} -- #{directory} | xz -9e > #{destination_path}")
      end
      destination_path
    end

    # generates patch files to changes to directory in destination_path
    # since from_id
    def format_patch(directory, from_id, destination_path)
      Dir.chdir(@directory) do
        run("git format-patch -o #{destination_path} --numbered #{from_id} -- #{directory}").split
      end
    end
  end

  class GitAlreadyInitedError < StandardError
  end
end
