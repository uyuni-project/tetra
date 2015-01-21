# encoding: UTF-8

require "spec_helper"

describe Tetra::Ant do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
    @path = create_mock_executable("ant")
  end

  let(:instance) { Tetra::Ant.new(".", mock_executable_path("ant")) }

  after(:each) do
    delete_mock_project
  end

  describe "#get_ant_commandline"  do
    it "returns commandline options for running Ant" do
      @project.from_directory do
        commandline = instance.get_ant_commandline([])
        expect(commandline).to eq "./#{@path} "
      end
    end
  end

  describe "#ant"  do
    it "runs Ant" do
      @project.from_directory do
        instance.ant(["extra-option"])
        expect(File.read("test_out").strip).to match(/extra-option$/)
      end
    end
  end
end
