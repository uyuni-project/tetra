# encoding: UTF-8

require 'spec_helper'

describe VersionMatcher do      
	
	it "splits full names into names and version numbers" do
		VersionMatcher.split_version("moio-3.2beta1").should eq(["moio", "3.2beta1"])
		VersionMatcher.split_version("3.2beta1").should eq(["", "3.2beta1"])
		VersionMatcher.split_version("v3.2beta1").should eq(["v", "3.2beta1"])
	end

	it "computes chunk distances" do
		VersionMatcher.chunk_distance(nil, "1").should eq(1)
		VersionMatcher.chunk_distance("alpha", nil).should eq(5)
		
		VersionMatcher.chunk_distance("1", "1").should eq(0)
		VersionMatcher.chunk_distance("1", "9").should eq(8)
		VersionMatcher.chunk_distance("1", "999").should eq(99)

		VersionMatcher.chunk_distance("snap", "SNAP").should eq(0)
		VersionMatcher.chunk_distance("snap", "snippete").should eq(5)
		VersionMatcher.chunk_distance("snap", "l"*999).should eq(99)
		
		VersionMatcher.chunk_distance("1", "SNAP").should eq(4)
		
		VersionMatcher.chunk_distance("0", "10").should eq(10)
		VersionMatcher.chunk_distance("0", "9").should eq(9)
	end
	
	it "finds the best match" do
		my_version = "1.0"
		available_versions = ["1.0", "1", "2.0", "1.0.1", "4.5.6.7.8"]
		VersionMatcher.best_match(my_version, available_versions).should eq("1.0")
		
		available_versions = ["3.0", "2.0", "1.0.1"]
		VersionMatcher.best_match(my_version, available_versions).should eq("1.0.1")

		available_versions = ["1.snap", "2.0", "4.0.1"]
		VersionMatcher.best_match(my_version, available_versions).should eq("1.snap")

		available_versions = ["1.10", "1.9", "2.0", "3.0.1"]
		VersionMatcher.best_match(my_version, available_versions).should eq("1.9")
		
		my_version = "1.snap"
		available_versions = ["1.snap", "1"]
		VersionMatcher.best_match(my_version, available_versions).should eq("1.snap")

		my_version = "1.very-very_very_longish"
		available_versions = ["1.snap", "1"]
		VersionMatcher.best_match(my_version, available_versions).should eq("1.snap")

		my_version = "1.snap"
		available_versions = []
		VersionMatcher.best_match(my_version, available_versions).should be_nil
	end
end

