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

  describe "#init" do
    it "inits a new project" do
      kit_path = File.join(@project_path, "kit")
      Dir.exists?(kit_path).should be_true

      src_path = File.join(@project_path, "src")
      Dir.exists?(src_path).should be_true

      @project.from_directory do
        `git tag`.strip.should eq("init")
        `git rev-list --all`.split("\n").length.should eq 1
      end
    end
  end

  describe ".set_status" do
    it "stores a project's status flag" do
      @project.from_directory do
        @project.set_status(:gathering)
        File.exists?(".gathering").should be_true
     end
    end
  end

  describe ".get_status" do
    it "gets a project's status flag" do
      @project.from_directory do
        @project.get_status(:gathering).should be_false
        `touch .gathering`
        @project.get_status(:gathering).should be_true
      end
    end
  end

  describe ".clear_status" do
    it "clears a project's status flag" do
      @project.from_directory do
        `touch .gathering`
        @project.get_status(:gathering).should be_true

        @project.clear_status(:gathering)
        @project.get_status(:gathering).should be_false
      end
    end
  end

  describe ".commit_all" do
    it "commits the project contents to git for later use" do
      @project.from_directory do
        `touch kit/test`

         @project.commit_all "test"

        `git rev-list --all`.split("\n").length.should eq 2
      end
    end
  end
  
  describe ".gather" do
    it "starts a gathering phase" do

      @project.from_directory do
        `touch src/test`
      end

      @project.gather.should eq :done

      @project.from_directory do
        @project.get_status(:gathering).should be_true
        `git rev-list --all`.split("\n").length.should eq 2
        `git diff-tree --no-commit-id --name-only -r HEAD`.split("\n").should include("src/test")
      end
    end
  end

  describe ".finish" do
    it "ends the current gathering phase" do
      @project.gather.should eq :done

      @project.from_directory do
        Dir.mkdir("src/a_b_c")
        `touch src/a_b_c/test`
        `touch kit/test`
      end

      @project.finish.should eq :gathering
      @project.get_status(:gathering).should be_false

      @project.from_directory do
        `git rev-list --all`.split("\n").length.should eq 5
        `git diff-tree --no-commit-id --name-only -r HEAD~2`.split("\n").should include("src/a_b_c/test")
        File.readlines("gjp_a_b_c_file_list").should include("test\n")
        File.readlines("gjp_kit_file_list").should include("test\n")
      end
    end

    it "ends the current dry-run phase" do
      @project.gather.should eq :done

      @project.from_directory do
        Dir.mkdir("src/a_b_c")
        `echo A > src/a_b_c/test`
      end

      @project.finish.should eq :gathering

      @project.dry_run.should eq :done

      @project.from_directory do
        `echo B > src/a_b_c/test`
        `touch src/a_b_c/test2`
        `touch kit/test`
      end

      @project.finish.should eq :dry_running
      @project.get_status(:dry_running).should be_false

      @project.from_directory do
        `git rev-list --all`.split("\n").length.should eq 10
        File.read("src/a_b_c/test").should eq "A\n"
        File.readlines("gjp_a_b_c_produced_file_list").should include("test2\n")
        File.readlines("gjp_a_b_c_file_list").should_not include("test2\n")

        `git diff-tree --no-commit-id --name-only -r HEAD~2`.split("\n").should_not include("src/a_b_c/test2")
        File.exists?("src/a_b_c/test2").should be_false
        File.readlines("gjp_kit_file_list").should include("test\n")
      end
    end
  end

  describe ".dry_run" do
    it "starts a dry running phase" do

      @project.from_directory do
        `touch src/test`
      end

      @project.dry_run.should eq :done

      @project.from_directory do
        @project.get_status(:dry_running).should be_true
        `git rev-list --all`.split("\n").length.should eq 2
        `git diff-tree --no-commit-id --name-only -r HEAD`.split("\n").should include("src/test")
      end
    end
  end
end
