# encoding: UTF-8

require "spec_helper"

describe Tetra::MavenKitItem do
  let(:group_id) { "com/company/project" }
  let(:artifact_id) { "artifact" }
  let(:version) { "1.0" }
  let(:dir) { File.join(group_id, artifact_id, version) }
  let(:pom) { File.join(dir, "#{artifact_id}-#{version}.pom") }
  let(:maven_kit_item) { Tetra::MavenKitItem.new(pom, File.join(dir, "pom.xml", [])) }

  describe "#provides_symbol" do
    it "returns the sepec Provides: symbol" do
      expect(maven_kit_item.provides_symbol).to eq("mvn(com.company.project:artifact)")
    end
  end

  describe "#provides_version" do
    it "returns the sepec Provides: version" do
      expect(maven_kit_item.provides_version).to eq("1.0")
    end
  end
end
