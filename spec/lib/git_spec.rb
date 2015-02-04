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

  describe "#commit_whole_directory" do
    it "commits all contents of a directory to git for later use" do
      Dir.chdir(@git_path) do
        FileUtils.touch("file1")
        Dir.mkdir("subdir")
        FileUtils.touch(File.join("subdir", "file2"))

        @git.commit_whole_directory("subdir", "test")

        files = `git ls-tree --name-only -r HEAD`.split("\n")

        expect(files).not_to include("file1")
        expect(files).to include("subdir/file2")
      end
    end
  end

  describe "#changed_files_between"  do
    it "lists files changed between tetra tags" do
      Dir.chdir(@git_path) do
        FileUtils.touch("file1")

        @git.commit_whole_directory(".", "test\ntetra: test_start")

        FileUtils.touch("file2")
        Dir.mkdir("subdir")
        FileUtils.touch(File.join("subdir", "file3"))

        @git.commit_whole_directory(".", "test\ntetra: test_end")

        FileUtils.touch("file4")
        @git.commit_whole_directory(".", "test\ntetra: test_after")

        start_id = @git.latest_id("tetra: test_start")
        end_id = @git.latest_id("tetra: test_end")

        files = @git.changed_files_between(start_id, end_id, "subdir")

        expect(files).not_to include("file1")
        expect(files).not_to include("file2")
        expect(files).to include("subdir/file3")
        expect(files).not_to include("file4")
      end
    end
  end
end
