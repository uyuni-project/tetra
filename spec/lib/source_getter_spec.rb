# encoding: UTF-8

require "spec_helper"
require "fileutils"

describe Gjp::SourceGetter do
  let(:source_getter) { Gjp::SourceGetter.new }

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

