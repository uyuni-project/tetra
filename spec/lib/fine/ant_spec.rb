# frozen_string_literal: true

require "spec_helper"

describe Tetra::Ant do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
    @path = create_mock_executable("ant")
  end

  after(:each) do
    delete_mock_project
  end

  describe "#get_ant_commandline" do
    it "returns commandline options for running Ant" do
      @project.from_directory do
        commandline = Tetra::Ant.commandline(".", mock_executable_dir("ant"))
        expect(commandline).to eq "./#{@path}"
      end
    end
  end
end
