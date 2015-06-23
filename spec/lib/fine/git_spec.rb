# encoding: UTF-8

require "spec_helper"

describe Tetra::Git do
  before(:each) do
    @git_path = File.expand_path(File.join("spec", "data", "test-repo"))
    Dir.mkdir(@git_path)

    @git = Tetra::Git.new(@git_path)
    @git.init
  end

  after(:each) do
    FileUtils.rm_rf(@git_path)
  end

  describe "#init" do
    it "complains if a double initialization is attempted" do
      expect do
        @git.init
      end.to raise_error(Tetra::GitAlreadyInitedError)
    end
  end

  describe "#latest_id" do
    it "does not find a commit with a non-existing comment" do
      Dir.chdir(@git_path) do
        @git.commit_file(".", "initial commit")
        expect(@git.latest_id("tetra: test")).to be_nil
      end
    end
    it "finds a commit with a certain comment" do
      Dir.chdir(@git_path) do
        @git.commit_file(".", "tetra: test")
        expect(@git.latest_id("tetra: test")).to eq `git rev-parse HEAD`.strip
      end
    end
  end

  describe "#commit_directories" do
    it "commits contents of multiple directories to git for later use" do
      Dir.chdir(@git_path) do
        FileUtils.touch("file1")
        Dir.mkdir("subdir1")
        FileUtils.touch(File.join("subdir1", "file2"))
        Dir.mkdir("subdir2")
        FileUtils.touch(File.join("subdir2", "file3"))

        @git.commit_directories(%w(subdir1 subdir2), "test")

        files = `git ls-tree --name-only -r HEAD`.split("\n")

        expect(files).not_to include("file1")
        expect(files).to include("subdir1/file2")
        expect(files).to include("subdir2/file3")
      end
    end
  end

  describe "#revert_directories" do
    it "reverts contents of multiple directories from git" do
      Dir.chdir(@git_path) do
        FileUtils.touch("expected_file")
        Dir.mkdir("subdir1")
        FileUtils.touch(File.join("subdir1", "expected_file"))
        Dir.mkdir("subdir2")
        FileUtils.touch(File.join("subdir2", "expected_file"))
        @git.commit_directories(["."], "test-start")

        FileUtils.touch(File.join("subdir1", "unexpected_file"))
        FileUtils.touch(File.join("subdir2", "unexpected_file"))

        @git.commit_directories(%w(subdir1 subdir2), "test-end")

        @git.revert_directories(%w(subdir1 subdir2), @git.latest_id("test-start"))

        files = Find.find(".").to_a

        expect(files).to include("./expected_file")
        expect(files).to include("./subdir1/expected_file")
        expect(files).to include("./subdir2/expected_file")
        expect(files).not_to include("./subdir1/unexpected_file")
        expect(files).not_to include("./subdir2/unexpected_file")
      end
    end
  end

  describe "#disable_special_files" do
    it "renames git special files to 'disable' them" do
      Dir.chdir(@git_path) do
        Dir.mkdir("src")
        FileUtils.touch(File.join("src", ".gitignore"))
        Dir.mkdir(File.join("src", ".git"))

        @git.disable_special_files("src")

        files = Dir.new("src").to_a

        expect(files).not_to include(".gitignore")
        expect(files).not_to include(".git")
      end
    end
  end

  describe "#changed_files" do
    it "checks if a directory is clean from changes" do
      Dir.chdir(@git_path) do
        @git.commit_file(".", "initial commit")
        Dir.mkdir("directory")
        FileUtils.touch(File.join("directory", "file"))
        expect(@git.changed_files("directory", "HEAD")).to include("directory/file")

        `git add directory/file`
        expect(@git.changed_files("directory", "HEAD")).to include("directory/file")

        @git.commit_file(File.join("directory", "file"), "test")
        expect(@git.changed_files("directory", "HEAD")).to be_empty

        expect(@git.changed_files("directory", "HEAD~")).to include("directory/file")
      end
    end
  end

  describe "#archive" do
    it "archives a version of a directory" do
      Dir.chdir(@git_path) do
        @git.commit_file(".", "initial commit")

        FileUtils.touch(File.join("outside_not_archived"))
        Dir.mkdir("directory")
        FileUtils.touch(File.join("directory", "file"))
        @git.commit_file("directory", "test")

        FileUtils.touch(File.join("directory", "later_not_archived"))

        @git.commit_file("directory", "later")

        destination_path = @git.archive("directory", @git.latest_id("test"), "archive.tar.xz")
        expect(destination_path).to match(/archive.tar.xz$/)

        file_list = `tar --list -f archive.tar.xz`.split
        expect(file_list).not_to include("outside_not_archived")
        expect(file_list).to include("directory/file")
        expect(file_list).not_to include("directory/later_not_archived")
      end
    end
  end

  describe "#format_patch" do
    it "creates patch files from commits" do
      Dir.chdir(@git_path) do
        outside_dir_file = File.join("outside_dir")
        inside_dir_not_patched_file = File.join("directory", "inside_dir_not_patched")
        inside_dir_patched_file = File.join("directory", "inside_dir_patched")

        Dir.mkdir("directory")
        FileUtils.touch(outside_dir_file)
        FileUtils.touch(inside_dir_not_patched_file)
        FileUtils.touch(inside_dir_patched_file)
        @git.commit_file(".", "initial")

        File.open(outside_dir_file, "w") { |f| f.write("A") }
        File.open(inside_dir_patched_file, "w") { |f| f.write("A") }
        @git.commit_file(".", "patch")

        Dir.mkdir("patches")
        patch_names = @git.format_patch("directory", "HEAD~", "patches")

        expect(patch_names).to include("patches/0001-patch.patch")

        patch_contents = File.readlines(File.join("patches", "0001-patch.patch"))
        expect(patch_contents).to include("--- a/#{inside_dir_patched_file}\n")
        expect(patch_contents).not_to include("--- a/#{outside_dir_file}\n")
        expect(patch_contents).not_to include("--- a/#{inside_dir_not_patched_file}\n")
        expect(patch_contents).to include("@@ -0,0 +1 @@\n")
        expect(patch_contents).to include("+A\n")
      end
    end
  end
end
