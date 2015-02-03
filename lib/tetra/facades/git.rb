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

    # returns a list of filenames that changed in the repo
    # between specified ids, in a certain directory
    def changed_files_between(start_id, end_id, directory)
      Dir.chdir(@directory) do
        run("git diff-tree \
              --no-commit-id \
              --name-only \
              -r #{start_id} #{end_id}\
              -- #{directory}"
        ).split("\n")
      end
    end

    # adds all files in the current directory,
    # removes all files not in the current directory,
    # commits with message
    def commit_whole_directory(message)
      Dir.chdir(@directory) do
        log.debug "committing with message: #{message}"

        run("git rm -r --cached --ignore-unmatch .")
        run("git add .")
        run("git commit --allow-empty -m \"#{message}\"")
      end
    end

    # commits one single file
    def commit_file(path, message)
      Dir.chdir(@directory) do
        log.debug "committing path #{path} with message: #{message}"
        run("git add #{path}")
        run("git commit --allow-empty -m \"#{message}\"")
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
  end

  class GitAlreadyInitedError < StandardError
  end
end
