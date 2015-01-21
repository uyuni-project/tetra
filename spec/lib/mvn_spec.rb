# encoding: UTF-8

require "spec_helper"

describe Tetra::Mvn do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
    @path = create_mock_executable("mvn")
  end

  let(:instance) { Tetra::Mvn.new(".", mock_executable_path("mvn")) }

  after(:each) do
    delete_mock_project
  end

  describe "#get_mvn_commandline"  do
    it "returns commandline options for running maven" do
      @project.from_directory do
        commandline = instance.get_mvn_commandline(["--otheroption"])
        expected_commandline = "./#{@path} -Dmaven.repo.local=./kit/m2 -s./kit/m2/settings.xml --otheroption"
        expect(commandline).to eq expected_commandline
      end
    end
  end

  describe "#mvn"  do
    it "runs maven" do
      @project.from_directory do
        instance.mvn(["extra-option"])
        expect(File.read("test_out").strip).to match(/extra-option$/)
      end
    end
  end

  describe "#get_source_jar"  do
    it "runs maven to get a source jar" do
      @project.from_directory do
        instance.get_source_jar("test_group", "test_artifact_id", "test_version")
        expected = /dependency:get -Dartifact=test_group:test_artifact_id:test_version:jar:sources -Dtransitive=false$/
        expect(File.read("test_out").strip).to match expected
      end
    end
  end

  describe "#get_effective_pom"  do
    it "runs maven to get an effective pom" do
      @project.from_directory do
        expect(instance.get_effective_pom("test.pom")).to eq "test.pom.effective"
        expect(File.read("test_out").strip).to match(/help:effective-pom -ftest.pom -Doutput=test.pom.effective$/)
      end
    end
  end
end
