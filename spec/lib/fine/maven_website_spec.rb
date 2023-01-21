# frozen_string_literal: true

require "spec_helper"

describe Tetra::MavenWebsite do
  let(:site) { Tetra::MavenWebsite.new }

  describe "#search_by_sha1" do
    it "uses search.maven.org to look for poms by jar SHA1" do
      result = site.search_by_sha1("546b5220622c4d9b2da45ad1899224b6ce1c8830").first

      expect(result["g"]).to eq("antlr")
      expect(result["a"]).to eq("antlrall")
      expect(result["v"]).to eq("2.7.2")
    end
  end

  describe "#search_by_name" do
    it "uses search.maven.org to look for poms by keyword (name)" do
      result = site.search_by_name("jruby").first

      # not much to test here
      expect(result).not_to be_nil
    end
  end

  describe "#search_by_group_id_and_artifact_id" do
    it "uses search.maven.org to look for poms by group and artifact id" do
      results = site.search_by_group_id_and_artifact_id("antlr", "antlrall")

      expect(results.any? { |result| result["id"] == "antlr:antlrall:2.7.2" }).to be_truthy
    end
  end

  describe "#search_by_maven_id" do
    it "uses search.maven.org to look for poms by group id, artifact id and version" do
      result = site.search_by_maven_id("antlr", "antlrall", "2.7.2")

      expect(result.first["id"]).to eq("antlr:antlrall:2.7.2")
    end
  end

  describe "#get_maven_id_from" do
    it "uses search.maven.org to look for poms" do
      expect(site.get_maven_id_from("g" => 1, "a" => 2, "v" => 3)).to eq([1, 2, 3])
    end
  end

  describe "#download_pom" do
    it "gets a pom from search.maven.org" do
      dir_path = File.join("spec", "data", "antlr")
      pom_path = File.join(dir_path, "pom.xml")
      expect(site.download_pom("antlr", "antlrall", "2.7.2")).to eq(File.read(pom_path))
    end
    it "returns an error on file not found" do
      expect do
        site.download_pom("does_not_exist", "does_not_exist", "does_not_exist")
      end.to raise_error(Tetra::NotFoundOnMavenWebsiteError)
    end
  end
end
