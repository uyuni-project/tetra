# encoding: UTF-8

module Gjp
  # facade to git, currently implemented with calls to the git command
  # prefixes all tags with "gjp_"
  class Git
    include Logging

    # inits a new git manager object pointing to the specified
    # directory
    def initialize(directory)
      @directory = directory
    end

    # inits a repo
    def init
      Dir.chdir(@directory) do
        if Dir.exist?(".git") == false
          `git init`
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
        prefixed_start_tag = "gjp_#{start_tag}"
        prefixed_end_tag = (
          if end_tag
            "gjp_#{end_tag}"
          else
            "HEAD"
          end
        )
        `git diff-tree --no-commit-id --name-only -r #{prefixed_start_tag} #{prefixed_end_tag} -- #{directory}`
          .split("\n")
      end
    end

    # adds all files in the current directory and removes
    # all files not in the current directory.
    # if tag is given, commit is also tagged
    def commit_whole_directory(message, tag = nil, tag_message = nil)
      Dir.chdir(@directory) do
        log.debug "committing with message: #{message}"

        # rename all .gitignore files by default as
        # they prevent snapshotting
        Find.find(".") do |file|
          if file =~ /\.gitignore$/
            FileUtils.mv(file, "#{file}_disabled_by_gjp")
          end
        end

        `git rm -r --cached --ignore-unmatch .`
        `git add .`
        `git commit -m "#{message}"`

        unless tag.nil?
          if !tag_message.nil?
            `git tag gjp_#{tag} -m "#{tag_message}"`
          else
            `git tag gjp_#{tag}`
          end
        end
      end
    end

    # returns the highest suffix found in tags with the given prefix
    def get_tag_maximum_suffix(prefix)
      Dir.chdir(@directory) do
        `git tag`.split.map do |tag|
          if tag =~ /^gjp_#{prefix}_([0-9]+)$/
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
        `git checkout -f gjp_#{tag} -- #{path}`

        # compute the list of deleted files
        files_in_tag = `git ls-tree --name-only -r gjp_#{tag} -- #{path}`.split("\n")
        files_in_head = `git ls-tree --name-only -r HEAD -- #{path}`.split("\n")
        files_added_after_head = `git ls-files -o -- #{path}`.split("\n")
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
        log.debug "calling git show gjp_#{tag}:#{path} > #{path}.old_version, output follows"
        `git show gjp_#{tag}:#{path} > #{path}.old_version`
        log.debug "calling git merge-file #{path} #{path}.old_version #{new_path}, output follows"
        `git merge-file #{path} #{path}.old_version #{new_path} \
          -L "newly generated" -L "previously generated" -L "user edited"`
        conflict_count = $?.exitstatus
        File.delete "#{path}.old_version"
        return conflict_count
      end
    end

    # deletes a tag
    def delete_tag(tag)
      Dir.chdir(@directory) do
        `git tag -d gjp_#{tag}`
      end
    end

    # returns the tag message
    def get_message(tag)
      `git cat-file tag gjp_#{tag}`.split.last
    end
  end

  class GitAlreadyInitedError < StandardError
  end
end
