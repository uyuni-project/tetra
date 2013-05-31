# encoding: UTF-8

require "spec_helper"
require "fileutils"

describe SourceGetter do
  describe ".get_source_from_git" do
    it "gets the sources from a git repo" do
      
      dir_path = File.join("spec", "data", "tomcat")
      pom_path = File.join(dir_path, "pom.xml")

      SourceGetter.get_source("git:https://github.com/apache/tomcat", pom_path, dir_path)

      repo_path = File.join(dir_path, "org.apache.tomcat:tomcat:7.0.40")
      file_path = File.join(repo_path, "LICENSE")
      File.open(file_path).readline.should eq "\n"
      
      FileUtils.rm_rf(repo_path)
    end
  end
end

