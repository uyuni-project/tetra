# encoding: UTF-8

require "spec_helper"
require "fileutils"

describe SourceGetter do
  describe ".get_source_from_git" do
    it "gets the sources from a git repo" do
      
      dir_path = File.join("spec", "data", "nailgun")
      pom_path = File.join(dir_path, "pom.xml")

      SourceGetter.get_source("git:git@github.com:martylamb/nailgun.git", pom_path, dir_path)

      repo_path = File.join(dir_path, "com.martiansoftware:nailgun-all:0.9.1")
      file_path = File.join(repo_path, "README.md")
      File.open(file_path).readline.should eq "nailgun\n"
      
      FileUtils.rm_rf(repo_path)
    end
  end
  
	describe ".get_source_from_svn" do
    it "gets the sources from an svn repo" do
      
      dir_path = File.join("spec", "data", "struts-apps")
      pom_path = File.join(dir_path, "pom.xml")

      SourceGetter.get_source("svn:http://svn.apache.org/repos/asf/struts/struts2/tags/STRUTS_2_3_14/apps", pom_path, dir_path)

      repo_path = File.join(dir_path, "org.apache.struts:struts2-apps:", "showcase")
      file_path = File.join(repo_path, "README.txt")
      File.open(file_path).readline.should eq "README.txt - showcase\n"
      
      FileUtils.rm_rf(repo_path)
    end
  end
end

