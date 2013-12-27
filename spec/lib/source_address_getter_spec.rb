# encoding: UTF-8

require 'spec_helper'

describe Gjp::SourceAddressGetter do
  let(:source_address_getter) { Gjp::SourceAddressGetter.new }

  describe "#get_source_address" do
    it "gets the source address from a pom file" do
      pom_path = File.join("spec", "data", "commons-logging", "pom.xml")
      source_address_getter.get_source_address(pom_path).should eq [:found_in_pom, "svn:http://svn.apache.org/repos/asf/commons/proper/logging/tags/commons-logging-1.1.1"]
    end
    
    it "gets the source address from Github" do
      pom_path = File.join("spec", "data", "antlr", "pom.xml")
      source_address_getter.get_source_address(pom_path).should eq [:found_in_github, "git:https://github.com/antlr/antlr4"]
    end
  end
end

