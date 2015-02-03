# encoding: UTF-8

module Tetra
  # facade to git, currently implemented with calls to the git command
  # prefixes all tags with "tetra_"
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

    # returns a list of filenames that changed in the repo
    # since the specified tag
    def changed_files_since(tag)
      changed_files_between(tag, nil, ".")
    end

    # returns a list of filenames that changed in the repo
    # between specified tags, in a certain directory
    def changed_files_between(start_tag, end_tag, directory)
      Dir.chdir(@directory) do
        prefixed_start_tag = "tetra_#{start_tag}"
        prefixed_end_tag = (
          if end_tag
            "tetra_#{end_tag}"
          else
            "HEAD"
          end
        )
        run("git diff-tree \
              --no-commit-id \
              --name-only \
              -r #{prefixed_start_tag} #{prefixed_end_tag}\
              -- #{directory}"
        ).split("\n")
      end
    end

    # adds all files in the current directory, removes
    # all files not in the current directory, commits
    # and tags with prefix
    def commit_whole_directory(message, tag, tag_message = nil)
      Dir.chdir(@directory) do
        log.debug "committing with message: #{message}"

        run("git rm -r --cached --ignore-unmatch .")
        run("git add .")
        run("git commit --allow-empty -m \"#{message}\"")

        if !tag_message.nil?
          run("git tag tetra_#{tag} -m \"#{tag_message}\"")
        else
          run("git tag tetra_#{tag}")
        end
      end
    end

    # commits and tags one single file
    # if tag is given, commit is also tagged
    def commit_file(path, message, tag)
      Dir.chdir(@directory) do
        log.debug "committing path #{path} with message: #{message}"
        run("git add #{path}")
        run("git commit --allow-empty -m \"#{message}\"")
        run("git tag tetra_#{tag}")
      end
    end

    # returns the highest suffix found in tags with the given prefix
    def get_tag_maximum_suffix(prefix)
      Dir.chdir(@directory) do
        run("git tag").split.map do |tag|
          if tag =~ /^tetra_#{prefix}_([0-9]+)$/
            Regexp.last_match[1].to_i
          else
            0
          end
        end.max || 0
      end
    end

    # reverts path contents as per specified tag
    def revert_whole_directory(path, tag)
      Dir.chdir(@directory) do
        # reverts added and modified files, both in index and working tree
        run("git checkout -f tetra_#{tag} -- #{path}")

        # compute the list of deleted files
        files_in_tag = run("git ls-tree --name-only -r tetra_#{tag} -- #{path}").split("\n")
        files_in_head = run("git ls-tree --name-only -r HEAD -- #{path}").split("\n")
        files_added_after_head = run("git ls-files -o -- #{path}").split("\n")
        files_to_delete = files_in_head - files_in_tag + files_added_after_head

        files_to_delete.each do |file|
          FileUtils.rm_rf(file)
        end
      end
    end

    # 3-way merges the git file at path with the one in new_path
    # assuming they have a common ancestor at the specified tag
    # returns the conflict count
    def merge_with_tag(path, new_path, tag)
      Dir.chdir(@directory) do
        run("git show tetra_#{tag}:#{path} > #{path}.old_version")
        run("git merge-file #{path} #{path}.old_version #{new_path} \
              -L \"newly generated\" \
              -L \"previously generated\" \
              -L \"user edited\"")
        conflict_count = $CHILD_STATUS.exitstatus
        File.delete("#{path}.old_version")
        return conflict_count
      end
    end

    # deletes a tag
    def delete_tag(tag)
      Dir.chdir(@directory) do
        run("git tag -d tetra_#{tag}")
      end
    end

    # returns the tag message
    def get_message(tag)
      run("git cat-file tag tetra_#{tag}").split.last
    end
  end

  class GitAlreadyInitedError < StandardError
  end
end
