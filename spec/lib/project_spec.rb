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
      }.to raise_error(ArgumentError)
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

      @project.get_status.should eq :gathering
    end
  end

  describe "#set_status" do
    it "stores a project's status flag" do
      @project.from_directory do
        @project.set_status :gathering
        File.exists?(".gathering").should be_true
     end
    end
  end

  describe "#get_status" do
    it "gets a project's status flag" do
      @project.from_directory do
        @project.get_status.should eq :gathering
        @project.set_status nil
        @project.get_status.should be_nil
      end
    end
  end

  describe "#take_snapshot" do
    it "commits the project contents to git for later use" do
      @project.from_directory do
        `touch kit/test`

         @project.take_snapshot "test", :revertable

        `git rev-list --all`.split("\n").length.should eq 2
         @project.latest_tag(:revertable).should eq "gjp_revertable_1"
      end
    end
  end
  
  describe "#gather" do
    it "starts a gathering phase" do
      @project.finish.should eq :gathering

      @project.gather.should be_true

      @project.from_directory do
        @project.get_status.should eq :gathering
      end
    end
  end

  describe "#finish" do
    it "ends the current gathering phase" do
      @project.finish.should eq :gathering
      @project.get_status.should be_nil
    end

    it "ends the current dry-run phase" do
      @project.from_directory do
        Dir.mkdir("src/abc")
        `echo A > src/abc/test`
      end

      @project.finish.should eq :gathering

      @project.dry_run.should be_true

      @project.from_directory do
        `echo B > src/abc/test`
        `touch src/abc/test2`
      end

      @project.finish.should eq :dry_running
      @project.get_status.should be_nil

      @project.from_directory do
        `git rev-list --all`.split("\n").length.should eq 6
        File.read("src/abc/test").should eq "A\n"
        File.readlines(File.join("file_lists", "abc_output")).should include("test2\n")

        `git diff-tree --no-commit-id --name-only -r HEAD~2`.split("\n").should_not include("src/abc/test2")
        File.exists?("src/abc/test2").should be_false
      end
    end
  end

  describe "#dry_run" do
    it "starts a dry running phase" do
      @project.finish.should eq :gathering

      @project.from_directory do
        `touch src/test`
      end

      @project.dry_run.should be_true

      @project.from_directory do
        @project.get_status.should eq :dry_running
        `git rev-list --all`.split("\n").length.should eq 2
        `git diff-tree --no-commit-id --name-only -r HEAD`.split("\n").should include("src/test")
      end
    end
  end
end
