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
end

