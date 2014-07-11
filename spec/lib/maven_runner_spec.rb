# encoding: UTF-8

require "spec_helper"

describe Tetra::MavenRunner do
  it_behaves_like Tetra::KitRunner
  include Tetra::Mockers

  before(:each) do
    create_mock_project
    @kit_runner = Tetra::MavenRunner.new(@project)
  end

  after(:each) do
    delete_mock_project
  end

  describe "#get_maven_commandline"  do
    it "returns commandline options for running maven" do
      executable_path = create_mock_executable("mvn")

      @project.from_directory do
        commandline = @kit_runner.get_maven_commandline(".", ["--otheroption"])
        expected_commandline = "./#{executable_path} -Dmaven.repo.local=./kit/m2 -s./kit/m2/settings.xml --otheroption"
        expect(commandline).to eq expected_commandline
      end
    end
    it "doesn't return commandline options if Maven is not available" do
      expect { @kit_runner.get_maven_commandline(".", []) }.to raise_error(Tetra::ExecutableNotFoundError)
    end
  end

  describe "#mvn"  do
    it "runs maven" do
      create_mock_executable("mvn")
      @project.from_directory do
        @kit_runner.mvn(["extra-option"])
        expect(File.read("test_out").strip).to match(/extra-option$/)
      end
    end
    it "doesn't run Maven if it is not available" do
      @project.from_directory do
        expect { @kit_runner.mvn([]) }.to raise_error(Tetra::ExecutableNotFoundError)
      end
    end
  end

  describe "#get_source_jar"  do
    it "runs maven to get a source jar" do
      create_mock_executable("mvn")
      @project.from_directory do
        @kit_runner.get_source_jar("test_group", "test_artifact_id", "test_version")
        expected = /dependency:get -Dartifact=test_group:test_artifact_id:test_version:jar:sources -Dtransitive=false$/
        expect(File.read("test_out").strip).to match expected
      end
    end
  end

  describe "#get_effective_pom"  do
    it "runs maven to get an effective pom" do
      create_mock_executable("mvn")
      @project.from_directory do
        expect(@kit_runner.get_effective_pom("test.pom")).to eq "test.pom.effective"
        expect(File.read("test_out").strip).to match(/help:effective-pom -ftest.pom -Doutput=test.pom.effective$/)
      end
    end
  end
end
