# encoding: UTF-8

require "spec_helper"
require "fileutils"

describe Tetra::SourceGetter do
  include Tetra::Mockers
  let(:source_getter) { Tetra::SourceGetter.new }

  before(:each) do
    create_mock_project
  end

  after(:each) do
    delete_mock_project
  end

  describe "#get_maven_source_jars" do
    it "gets sources for jars in the Maven repo through Maven itself" do
      create_mock_executable("mvn")

      @project.from_directory(File.join("kit", "m2")) do
        jar_dir_path = File.join("net", "test", "artifact", "1.0")
        jar_path = File.join(jar_dir_path, "artifact-1.0-blabla.jar")
        FileUtils.mkdir_p(jar_dir_path)
        FileUtils.touch(jar_path)

        successes, failures = source_getter.get_maven_source_jars(@project)
        commandline = File.read(File.join("..", "..", "test_out")).strip
        commandline.should match(/-Dartifact=net.test:artifact:1.0:jar:sources -Dtransitive=false$/)
        successes.should include File.join(".", "kit", "m2", jar_path)
        failures.should eq []
      end
    end
  end
end
