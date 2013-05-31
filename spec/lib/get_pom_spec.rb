# encoding: UTF-8

require 'spec_helper'

describe PomGetter do
  describe ".get_pom" do
    it "gets the pom from a directory" do
      dir_path = File.join("spec", "data", "commons-logging")
      pom_path = File.join(dir_path, "pom.xml")
      PomGetter.get_pom(dir_path).should eq(File.read(pom_path))
    end
    
    it "gets the pom from a jar" do
      dir_path = File.join("spec", "data", "commons-logging")
      pom_path = File.join(dir_path, "pom.xml")
      jar_path = File.join(dir_path, "commons-logging-1.1.1.jar")
      PomGetter.get_pom(jar_path).should eq(File.read(pom_path))
    end

    it "gets the pom from sha1" do
      dir_path = File.join("spec", "data", "antlr")
      pom_path = File.join(dir_path, "pom.xml")
      jar_path = File.join(dir_path, "antlr-2.7.2.jar")
      PomGetter.get_pom(jar_path).should eq(File.read(pom_path))
    end
    
    it "gets the pom from a heuristic" do
      dir_path = File.join("spec", "data", "nailgun")
      pom_path = File.join(dir_path, "pom.xml")
      jar_path = File.join(dir_path, "nailgun-0.7.1.jar")
      PomGetter.get_pom(jar_path).should eq(File.read(pom_path))
    end         
  end
end

