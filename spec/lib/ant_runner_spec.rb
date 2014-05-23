# encoding: UTF-8

require "spec_helper"
require "lib/kit_runner_spec"

describe Gjp::AntRunner do
  it_behaves_like Gjp::KitRunner
  include Gjp::Mockers

  before(:each) do
    create_mock_project
    @kit_runner = Gjp::AntRunner.new(@project)
  end

  after(:each) do
    delete_mock_project
  end

  describe "#get_ant_commandline"  do
    it "returns commandline options for running Ant" do
      executable_path = create_mock_executable("ant")
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
      executable_path = create_mock_executable("ant")
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
