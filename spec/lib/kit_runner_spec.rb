# encoding: UTF-8

require 'spec_helper'

describe Gjp::KitRunner do

  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Gjp::Project.init(@project_path)
    @project = Gjp::Project.new(@project_path)
    @kit_runner = Gjp::KitRunner.new(@project)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  describe "#find_executable"  do
    it "finds an executable in kit" do
      executable_path = mock_executable("mvn", @project_path)
      @kit_runner.find_executable("mvn").should eq executable_path
    end
    it "doesn't find a Maven executable in kit" do
      @kit_runner.find_executable("mvn").should be_nil
    end
  end

  describe "#get_maven_commandline"  do
    it "returns commandline options for running maven" do
      executable_path = mock_executable("mvn", @project_path)

      @project.from_directory do
        commandline = @kit_runner.get_maven_commandline(".")
        commandline.should eq "./#{executable_path} -Dmaven.repo.local=./kit/m2 -s./kit/m2/settings.xml"
      end
    end
    it "doesn't return commandline options if Maven is not available" do
      expect { @kit_runner.get_maven_commandline(".") }.to raise_error(Gjp::ExecutableNotFoundError)
    end
  end

  describe "#mvn"  do
    it "runs maven" do
      mock_executable("mvn", @project_path)
      @project.from_directory do
        @kit_runner.mvn(["extra-option"])
        File.read("test_out").strip.should match /extra-option$/
      end
    end
    it "doesn't run Maven if it is not available" do
      @project.from_directory do
        expect { @kit_runner.mvn([]) }.to raise_error(Gjp::ExecutableNotFoundError)
      end
    end
  end


  describe "#get_ant_commandline"  do
    it "returns commandline options for running Ant" do
      executable_path = mock_executable("ant", @project_path)

      @project.from_directory do
        commandline = @kit_runner.get_ant_commandline(".")
        commandline.should eq "./#{executable_path}"
      end
    end
    it "doesn't return commandline options if Ant is not available" do
      expect { @kit_runner.get_ant_commandline(".") }.to raise_error(Gjp::ExecutableNotFoundError)
    end
  end

  describe "#ant"  do
    it "runs Ant" do
      mock_executable("ant", @project_path)
      @project.from_directory do
        @kit_runner.ant(["extra-option"])
        File.read("test_out").strip.should match /extra-option$/
      end
    end
    it "doesn't run Ant if it is not available" do
      @project.from_directory do
        expect { @kit_runner.ant([]) }.to raise_error(Gjp::ExecutableNotFoundError)
      end
    end
  end
end
