# encoding: UTF-8

require 'spec_helper'

describe Gjp::Project do
  before(:all) do
    @project_path = File.join("spec", "data", "test-project")
  end

  describe ".init" do

    it "inits a new project" do
      Dir.mkdir(@project_path)

      project = Gjp::Project.new(@project_path)
      project.init

      kit_path = File.join(@project_path, "kit")
      Dir.exists?(kit_path).should be_true

      src_path = File.join(@project_path, "src")
      Dir.exists?(src_path).should be_true

      Dir.chdir(@project_path) do
        `git tag`.strip.should eq("init")
        `git log`.split("\n").length.should eq(5)
      end
    end
  end

  after(:all) do
    FileUtils.rm_rf(@project_path)
  end
end
