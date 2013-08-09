# encoding: UTF-8

require 'spec_helper'

describe Gjp::MavenRunner do

  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Gjp::Project.init(@project_path)
    @project = Gjp::Project.new(@project_path)
    @project.gather

    # mock a Maven executable
    Dir.chdir(@project_path) do
      @bin_dir = File.join("kit", "mvn", "bin")
      FileUtils.mkdir_p(@bin_dir)
      @maven_executable = File.join(@bin_dir, "mvn")
      File.open(@maven_executable, "w") { |io| io.puts "echo $0 $*>test_out" }
      File.chmod(0777, @maven_executable)
    end

    @project.finish

    @maven_runner = Gjp::MavenRunner.new(@project)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  describe "#find_maven_executable"  do
    it "looks for Maven in kit" do
      @maven_runner.find_maven_executable.should eq @maven_executable
    end
  end

  describe "#get_maven_commandline"  do
    it "returns commandline options for running maven" do
      kit_full_path = File.join(@project.full_path, "kit")
      commandline = @maven_runner.get_maven_commandline(kit_full_path, @project.full_path)

      commandline.should eq "./#{@maven_executable} -Dmaven.repo.local=`readlink -e ./kit/m2` -s`readlink -e ./kit/m2/settings.xml`"
    end
  end

  describe "#mvn"  do
    it "runs maven" do
      @project.from_directory do
        @maven_runner.mvn(["extra-option"])
        File.read("test_out").strip.should match /extra-option$/
      end
    end
  end
end
