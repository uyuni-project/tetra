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
            
    it "computes chunk distances" do
      PomGetter.chunk_distance(nil, "1").should eq(1)
      PomGetter.chunk_distance("alpha", nil).should eq(5)
      
      PomGetter.chunk_distance("1", "1").should eq(0)
      PomGetter.chunk_distance("1", "9").should eq(8)
      PomGetter.chunk_distance("1", "999").should eq(99)

      PomGetter.chunk_distance("snap", "SNAP").should eq(0)
      PomGetter.chunk_distance("snap", "snippete").should eq(5)
      PomGetter.chunk_distance("snap", "l"*999).should eq(99)
      
      PomGetter.chunk_distance("1", "SNAP").should eq(4)
      
      PomGetter.chunk_distance("0", "10").should eq(10)
      PomGetter.chunk_distance("0", "9").should eq(9)
    end
    
    it "finds the best match" do
      my_version = "1.0"
      available_versions = ["1.0", "1", "2.0", "1.0.1", "4.5.6.7.8"]
      PomGetter.best_match(my_version, available_versions).should eq("1.0")
      
      available_versions = ["3.0", "2.0", "1.0.1"]
      PomGetter.best_match(my_version, available_versions).should eq("1.0.1")

      available_versions = ["1.snap", "2.0", "4.0.1"]
      PomGetter.best_match(my_version, available_versions).should eq("1.snap")

      available_versions = ["1.10", "1.9", "2.0", "3.0.1"]
      PomGetter.best_match(my_version, available_versions).should eq("1.9")
      
      my_version = "1.snap"
      available_versions = ["1.snap", "1"]
      PomGetter.best_match(my_version, available_versions).should eq("1.snap")

      my_version = "1.very-very_very_longish"
      available_versions = ["1.snap", "1"]
      PomGetter.best_match(my_version, available_versions).should eq("1.snap")

      my_version = "1.snap"
      available_versions = []
      PomGetter.best_match(my_version, available_versions).should be_nil
    end
  end
end

