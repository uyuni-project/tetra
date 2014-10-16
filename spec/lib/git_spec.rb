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

  describe "#init"  do
    it "complains if a double initialization is attempted" do
      expect do
        @git.init
      end.to raise_error(Tetra::GitAlreadyInitedError)
    end
  end

  describe "#commit_whole_directory" do
    it "commits all contents of a directory to git for later use" do
      Dir.chdir(@git_path) do
        File.open("file1", "w") do |file|
          file.write "test"
        end

        @git.commit_whole_directory("test", :test)

        files = `git ls-tree --name-only -r HEAD`.split("\n")

        expect(files).to include("file1")
      end
    end
  end

  describe "#changed_files_since"  do
    it "lists files changed since a tetra tag" do
      Dir.chdir(@git_path) do
        File.open("file1", "w") do |file|
          file.write "test"
        end

        @git.commit_whole_directory("test", :test_start)

        File.open("file2", "w") do |file|
          file.write "test"
        end

        @git.commit_whole_directory("test end", :test_end)

        files = @git.changed_files_since(:test_start)

        expect(files).not_to include("file1")
        expect(files).to include("file2")
      end
    end
  end

  describe "#changed_files_between"  do
    it "lists files changed between tetra tags" do
      Dir.chdir(@git_path) do
        File.open("file1", "w") do |file|
          file.write "test"
        end

        @git.commit_whole_directory("test", :test_start)

        File.open("file2", "w") do |file|
          file.write "test"
        end
        Dir.mkdir("subdir")
        File.open(File.join("subdir", "file3"), "w") do |file|
          file.write "test"
        end

        @git.commit_whole_directory("test", :test_end)

        File.open("file4", "w") do |file|
          file.write "test"
        end

        @git.commit_whole_directory("test", :test_after)

        files = @git.changed_files_between(:test_start, :test_end, "subdir")

        expect(files).not_to include("file1")
        expect(files).not_to include("file2")
        expect(files).to include("subdir/file3")
        expect(files).not_to include("file4")
      end
    end
  end
end
