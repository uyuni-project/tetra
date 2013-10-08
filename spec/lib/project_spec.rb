# encoding: UTF-8

require 'spec_helper'

describe Gjp::Project do
  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Gjp::Project.init(@project_path)
    @project = Gjp::Project.new(@project_path)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  describe "#is_project"  do
    it "checks if a directory is a gjp project or not" do
      Gjp::Project.is_project(@project_path).should be_true    
      Gjp::Project.is_project(File.join(@project_path, "..")).should be_false
    end
  end

  describe "#find_project_dir"  do
    it "recursively the parent project directory" do
      expanded_path = File.expand_path(@project_path)
      Gjp::Project.find_project_dir(expanded_path).should eq expanded_path
      Gjp::Project.find_project_dir(File.expand_path("src", @project_path)).should eq expanded_path
      Gjp::Project.find_project_dir(File.expand_path("kit", @project_path)).should eq expanded_path

      expect {
        Gjp::Project.find_project_dir(File.expand_path("..", @project_path)).should raise_error
      }.to raise_error(Gjp::NotGjpDirectoryException)
    end
  end

  describe "full_path" do
    it "returns the project's full path" do
      @project.full_path.should eq File.expand_path(@project_path)
    end
  end

  describe "#init" do
    it "inits a new project" do
      kit_path = File.join(@project_path, "kit")
      Dir.exists?(kit_path).should be_true

      src_path = File.join(@project_path, "src")
      Dir.exists?(src_path).should be_true
    end
  end

  describe "#is_dry_running" do
    it "checks if a project is dry running" do
      @project.from_directory do
        @project.is_dry_running.should be_false
        @project.dry_run
        @project.is_dry_running.should be_true
        @project.finish(false)
        @project.is_dry_running.should be_false
      end
    end
  end

  describe "#take_snapshot" do
    it "commits the project contents to git for later use" do
      @project.from_directory do
        `touch kit/test`

         @project.take_snapshot "test", :revertable

        `git rev-list --all`.split("\n").length.should eq 2
         @project.latest_tag(:revertable).should eq "revertable_1"
      end
    end
  end
  
  describe "#finish" do
    it "ends the current dry-run phase after a successful build" do
      @project.from_directory do
        Dir.mkdir("src/abc")
        `echo A > src/abc/test`
      end

      @project.finish(true).should be_false
      @project.finish(false).should be_false

      @project.dry_run.should be_true

      @project.from_directory do
        `echo B > src/abc/test`
        `touch src/abc/test2`
      end

      @project.finish(false).should be_true
      @project.is_dry_running.should be_false

      @project.from_directory do
        `git rev-list --all`.split("\n").length.should eq 5
        File.read("src/abc/test").should eq "A\n"
        File.readlines(File.join("file_lists", "abc_output")).should include("test2\n")

        `git diff-tree --no-commit-id --name-only -r HEAD~`.split("\n").should_not include("src/abc/test2")
        File.exists?("src/abc/test2").should be_false
      end
    end
    it "ends the current dry-run phase after a failed build" do
      @project.from_directory do
        Dir.mkdir("src/abc")
        `echo A > src/abc/test`
        `echo A > kit/test`
      end

      @project.finish(true).should be_false
      @project.finish(false).should be_false

      @project.dry_run.should be_true

      @project.from_directory do
        `echo B > src/abc/test`
        `touch src/abc/test2`
        `echo B > kit/test`
        `touch kit/test2`
      end

      @project.finish(true).should be_true
      @project.is_dry_running.should be_false

      @project.from_directory do
        `git rev-list --all`.split("\n").length.should eq 2
        File.read("src/abc/test").should eq "A\n"
        File.exists?("src/abc/test2").should be_false

        File.read("kit/test").should eq "A\n"
        File.exists?("kit/test2").should be_false

        File.exists?(File.join("file_lists", "abc_output")).should be_false
      end
    end
  end

  describe "#dry_run" do
    it "starts a dry running phase" do
      @project.finish(false).should be_false

      @project.from_directory do
        `touch src/test`
      end

      @project.dry_run.should be_true

      @project.from_directory do
        @project.is_dry_running.should be_true
        `git rev-list --all`.split("\n").length.should eq 2
        `git diff-tree --no-commit-id --name-only -r HEAD`.split("\n").should include("src/test")
      end
    end
  end
end
