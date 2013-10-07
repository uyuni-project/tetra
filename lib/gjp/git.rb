# encoding: UTF-8

module Gjp
  # encapsulates git, all methods refer to the current directory
  class Git
    include Logger

    # inits a repo
    def self.init
      if Dir.exists?(".git") == false
        `git init`
      else
        raise GitAlreadyInitedException
      end
    end

    # returns a list of filenames that changed in the repo
    # since the specified tag
    def changed_files_since(tag)
      `git diff-tree --no-commit-id --name-only -r gjp_#{tag} HEAD`.split("\n")
    end

    # adds all files in the current directory and removes
    # all files not in the current directory.
    # if tag is given, commit is also tagged
    def commit_whole_directory(message, tag = nil)
      log.debug "committing with message: #{message}"

      `git rm -r --cached --ignore-unmatch .`
      `git add .`
      `git commit -m "#{message}"`

      if tag != nil
        `git tag gjp_#{tag}`
      end
    end

    # returns the highest suffix found in tags with the given prefix
    def get_tag_maximum_suffix(prefix)
      `git tag`.split.map do |tag|
        if tag =~ /^gjp_#{prefix}_([0-9]+)$/
          $1.to_i
        else
          0
        end
       end.max or 0
    end

    # reverts path contents as per specified tag
    def revert_whole_directory(path, tag)
      `git rm -rf --ignore-unmatch #{path}`
      `git checkout -f gjp_#{tag} -- #{path}`

      `git clean -f -d #{path}`
    end

    # 3-way merges the git file at path with the one in new_path
    # assuming they have a common ancestor at the specified tag
    def merge_with_tag(path, new_path, tag)
      `git show gjp_#{tag}:#{path} > #{path}.old_version`
      `git merge-file --ours #{path} #{path}.old_version #{new_path}`
      File.delete "#{path}.old_version"
    end
  end

  class GitAlreadyInitedException < Exception
  end
end
