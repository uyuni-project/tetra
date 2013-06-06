# encoding: UTF-8

require 'spec_helper'

describe Gjp::SourceAddressGetter do
  describe ".get_source_address" do
    it "gets the source address from a pom file" do
      pom_path = File.join("spec", "data", "commons-logging", "pom.xml")
      Gjp::SourceAddressGetter.get_source_address(pom_path).should eq "svn:http://svn.apache.org/repos/asf/commons/proper/logging/tags/commons-logging-1.1.1"
    end
    
    it "gets the source address from Github" do
      pom_path = File.join("spec", "data", "antlr", "pom.xml")
      Gjp::SourceAddressGetter.get_source_address(pom_path).should eq "git:https://github.com/antlr/antlr4"
    end
  end
end

