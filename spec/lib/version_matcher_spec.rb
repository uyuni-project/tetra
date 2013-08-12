# encoding: UTF-8

require 'spec_helper'

describe Gjp::VersionMatcher do      
  let(:version_matcher) { Gjp::VersionMatcher.new }

  describe "#split_version" do
    it "splits full names into names and version numbers" do
      version_matcher.split_version("moio-3.2beta1").should eq(["moio", "3.2beta1"])
      version_matcher.split_version("3.2beta1").should eq(["", "3.2beta1"])
      version_matcher.split_version("v3.2beta1").should eq(["v", "3.2beta1"])
    end
  end

  describe "#chunk_distance" do
    it "computes chunk distances" do
      version_matcher.chunk_distance(nil, "1").should eq(1)
      version_matcher.chunk_distance("alpha", nil).should eq(5)
      
      version_matcher.chunk_distance("1", "1").should eq(0)
      version_matcher.chunk_distance("1", "9").should eq(8)
      version_matcher.chunk_distance("1", "999").should eq(99)

      version_matcher.chunk_distance("snap", "SNAP").should eq(0)
      version_matcher.chunk_distance("snap", "snippete").should eq(5)
      version_matcher.chunk_distance("snap", "l"*999).should eq(99)
      
      version_matcher.chunk_distance("1", "SNAP").should eq(4)
      
      version_matcher.chunk_distance("0", "10").should eq(10)
      version_matcher.chunk_distance("0", "9").should eq(9)
    end
  end
  
  describe "#best_match" do
    it "finds the best match" do
      my_version = "1.0"
      available_versions = ["1.0", "1", "2.0", "1.0.1", "4.5.6.7.8"]
      version_matcher.best_match(my_version, available_versions).should eq("1.0")
      
      available_versions = ["3.0", "2.0", "1.0.1"]
      version_matcher.best_match(my_version, available_versions).should eq("1.0.1")

      available_versions = ["1.snap", "2.0", "4.0.1"]
      version_matcher.best_match(my_version, available_versions).should eq("1.snap")

      available_versions = ["1.10", "1.9", "2.0", "3.0.1"]
      version_matcher.best_match(my_version, available_versions).should eq("1.9")
      
      my_version = "1.snap"
      available_versions = ["1.snap", "1"]
      version_matcher.best_match(my_version, available_versions).should eq("1.snap")

      my_version = "1.very-very_very_longish"
      available_versions = ["1.snap", "1"]
      version_matcher.best_match(my_version, available_versions).should eq("1.snap")

      my_version = "1.snap"
      available_versions = []
      version_matcher.best_match(my_version, available_versions).should be_nil
    end
  end
end

