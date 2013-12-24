# encoding: UTF-8

require "spec_helper"
require "fileutils"

describe Gjp::SourceGetter do
  include Gjp::Mockers
  let(:source_getter) { Gjp::SourceGetter.new }

  describe "#get_maven_source_jars" do
    before(:each) do
      create_mock_project
    end

    it "gets sources for jars in the Maven repo through Maven itself" do
      create_mock_executable("mvn")

      @project.from_directory(File.join("kit", "m2")) do
        jar_dir_path = File.join("net", "test", "artifact", "1.0")
        jar_path = File.join(jar_dir_path, "artifact-1.0-blabla.jar")
        FileUtils.mkdir_p(jar_dir_path)
        FileUtils.touch(jar_path)

        successes, failures = source_getter.get_maven_source_jars(@project)
        commandline = File.read(File.join("..", "..", "test_out")).strip
        commandline.should match /-Dartifact=net.test:artifact:1.0:jar:sources -Dtransitive=false$/
        successes.should include File.join(".", "kit", "m2", jar_path)
        failures.should eq []
      end
    end

    after(:each) do
      delete_mock_project
    end
  end

  describe "#get_source_from_git" do
    it "gets the sources from a git repo" do
      dir_path = File.join("spec", "data", "nailgun")
      pom_path = File.join(dir_path, "pom.xml")
      repo_path = File.join(dir_path, "com.martiansoftware:nailgun-all:0.9.1")
      file_path = File.join(repo_path, "README.md")

      FileUtils.rm_rf(repo_path)

      source_getter.get_source("git:git@github.com:martylamb/nailgun.git", pom_path, dir_path)

      File.open(file_path).readline.should eq "nailgun\n"
    end
  end
  
	describe "#get_source_from_svn" do
    it "gets the sources from an svn repo" do  
      dir_path = File.join("spec", "data", "struts-apps")
      pom_path = File.join(dir_path, "pom.xml")
      repo_path = File.join(dir_path, "org.apache.struts:struts2-apps:")
      file_path = File.join(repo_path, "showcase", "README.txt")

      FileUtils.rm_rf(repo_path)

      source_getter.get_source("svn:http://svn.apache.org/repos/asf/struts/struts2/tags/STRUTS_2_3_14/apps", pom_path, dir_path)

      File.open(file_path).readline.should eq "README.txt - showcase\n"
    end
  end
end

