# encoding: UTF-8

require "spec_helper"

describe Tetra::Ant do
  it_behaves_like Tetra::KitRunner
  include Tetra::Mockers

  before(:each) do
    create_mock_project
    @kit_runner = Tetra::Ant.new(@project)
  end

  after(:each) do
    delete_mock_project
  end

  describe "#get_ant_commandline"  do
    it "returns commandline options for running Ant" do
      executable_path = create_mock_executable("ant")
      @project.from_directory do
        commandline = @kit_runner.get_ant_commandline(".")
        expect(commandline).to eq "./#{executable_path}"
      end
    end
    it "doesn't return commandline options if Ant is not available" do
      expect { @kit_runner.get_ant_commandline(".") }.to raise_error(Tetra::ExecutableNotFoundError)
    end
  end

  describe "#ant"  do
    it "runs Ant" do
      create_mock_executable("ant")
      @project.from_directory do
        @kit_runner.ant(["extra-option"])
        expect(File.read("test_out").strip).to match(/extra-option$/)
      end
    end
    it "doesn't run Ant if it is not available" do
      @project.from_directory do
        expect { @kit_runner.ant([]) }.to raise_error(Tetra::ExecutableNotFoundError)
      end
    end
  end
end
