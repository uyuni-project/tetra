# frozen_string_literal: true

require "spec_helper"

describe Tetra::Mvn do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
    @path = create_mock_executable("mvn")
  end

  after(:each) do
    delete_mock_project
  end

  describe "#get_mvn_commandline" do
    it "returns commandline options for running maven" do
      @project.from_directory do
        commandline = Tetra::Mvn.commandline(".", mock_executable_dir("mvn"))

        # Use implicit string concatenation for cleaner multi-line expectation
        # Note: Since we pass "." as project_path, the result should be relative
        expected_commandline = "./#{@path} " \
                               "-Dmaven.repo.local=./kit/m2 " \
                               "--settings ./kit/m2/settings.xml " \
                               "--strict-checksums"

        expect(commandline).to eq expected_commandline
      end
    end
  end
end
