# encoding: UTF-8

require 'spec_helper'

describe Gjp::Project do
  before(:all) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)
  end

  let(:project) { Gjp::Project.new(@project_path) }

  describe ".init" do
    it "inits a new project" do
      project.init

      kit_path = File.join(@project_path, "kit")
      Dir.exists?(kit_path).should be_true

      src_path = File.join(@project_path, "src")
      Dir.exists?(src_path).should be_true

      Dir.chdir(@project_path) do
        `git tag`.strip.should eq("init")
        `git rev-list --all`.split("\n").length.should eq 1
      end
    end
  end

  describe ".set_status" do
    it "stores a project's status flag" do
      Dir.chdir(@project_path) do
        project.set_status(:gathering)
        File.exists?(".gathering").should be_true

        project.clear_status(:gathering)
        File.exists?(".gathering").should be_false
      end
    end
  end

  describe ".get_status" do
    it "gets a project's status flag" do
      Dir.chdir(@project_path) do
        project.get_status(:gathering).should be_false

        project.set_status(:gathering)
        project.get_status(:gathering).should be_true
      end
    end
  end

  describe ".clear_status" do
    it "clears a project's status flag" do
      Dir.chdir(@project_path) do
        project.get_status(:gathering).should be_true

        project.clear_status(:gathering)
        project.get_status(:gathering).should be_false
      end
    end
  end

  describe ".commit_all" do
    it "commits the project contents to git for later use" do
      Dir.chdir(@project_path) do
        `touch kit/test`

         project.commit_all "test"

        `git rev-list --all`.split("\n").length.should eq(2)
      end
    end
  end
  
  describe ".gather" do
    it "starts a gathering phase" do

      Dir.chdir(@project_path) do
        `touch src/test`
      end

      project.gather.should eq(:done)

      Dir.chdir(@project_path) do
        project.get_status(:gathering).should be_true
        `git rev-list --all`.split("\n").length.should eq 3
        `git diff-tree --no-commit-id --name-only -r HEAD`.split("\n").should include("src/test")
      end
    end
  end

  after(:all) do
    FileUtils.rm_rf(@project_path)
  end
end
