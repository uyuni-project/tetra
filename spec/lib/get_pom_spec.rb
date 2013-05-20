# encoding: UTF-8

require 'spec_helper'

describe PomGetter do
  describe ".get_pom" do
    dir_path = File.join("spec", "data", "commons-logging")
    jar_path = File.join(dir_path, "commons-logging-1.1.1.jar")
    pom_path = File.join(dir_path, "pom.xml")

    it "gets the pom from a directory" do
      PomGetter.get_pom(dir_path).should eq(File.read(pom_path))
    end
    
    it "gets the pom from a jar" do
      PomGetter.get_pom(jar_path).should eq(File.read(pom_path))
    end
  end
end

