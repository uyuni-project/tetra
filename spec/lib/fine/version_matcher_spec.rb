# frozen_string_literal: true

require "spec_helper"

describe Tetra::VersionMatcher do
  let(:version_matcher) { Tetra::VersionMatcher.new }

  describe "#split_version" do
    it "splits full names into names and version numbers" do
      expect(version_matcher.split_version("moio-3.2beta1")).to eq(["moio", "3.2beta1"])
      expect(version_matcher.split_version("3.2beta1")).to eq(["", "3.2beta1"])
      expect(version_matcher.split_version("v3.2beta1")).to eq(["v", "3.2beta1"])
    end
  end

  describe "#chunk_distance" do
    it "computes chunk distances" do
      expect(version_matcher.chunk_distance(nil, "1")).to eq(1)
      expect(version_matcher.chunk_distance("alpha", nil)).to eq(5)

      expect(version_matcher.chunk_distance("1", "1")).to eq(0)
      expect(version_matcher.chunk_distance("1", "9")).to eq(8)
      expect(version_matcher.chunk_distance("1", "999")).to eq(99)

      expect(version_matcher.chunk_distance("snap", "SNAP")).to eq(0)
      expect(version_matcher.chunk_distance("snap", "snippete")).to eq(5)
      expect(version_matcher.chunk_distance("snap", "l" * 999)).to eq(99)

      expect(version_matcher.chunk_distance("1", "SNAP")).to eq(4)

      expect(version_matcher.chunk_distance("0", "10")).to eq(10)
      expect(version_matcher.chunk_distance("0", "9")).to eq(9)
    end
  end

  describe "#best_match" do
    it "finds the best match" do
      my_version = "1.0"
      available_versions = ["1.0", "1", "2.0", "1.0.1", "4.5.6.7.8"]
      expect(version_matcher.best_match(my_version, available_versions)).to eq("1.0")

      available_versions = ["3.0", "2.0", "1.0.1"]
      expect(version_matcher.best_match(my_version, available_versions)).to eq("1.0.1")

      available_versions = ["1.snap", "2.0", "4.0.1"]
      expect(version_matcher.best_match(my_version, available_versions)).to eq("1.snap")

      available_versions = ["1.10", "1.9", "2.0", "3.0.1"]
      expect(version_matcher.best_match(my_version, available_versions)).to eq("1.9")

      my_version = "1.snap"
      available_versions = ["1.snap", "1"]
      expect(version_matcher.best_match(my_version, available_versions)).to eq("1.snap")

      my_version = "1.very-very_very_longish"
      available_versions = ["1.snap", "1"]
      expect(version_matcher.best_match(my_version, available_versions)).to eq("1.snap")

      my_version = "1.snap"
      available_versions = []
      expect(version_matcher.best_match(my_version, available_versions)).to be_nil
    end
  end
end
