# encoding: UTF-8

require "spec_helper"

describe Tetra::MavenKitItem do
  let(:group_id) { "com/company/project" }
  let(:artifact_id) { "artifact" }
  let(:version) { "1.0" }
  let(:dir) { File.join(group_id, artifact_id, version) }
  let(:pom) { File.join(dir, "#{artifact_id}-#{version}.pom") }
  let(:maven_kit_item) { Tetra::MavenKitItem.new(pom, File.join(dir, "pom.xml", [])) }

  describe "#group_id" do
    it "returns the group id" do
      expect(maven_kit_item.group_id).to eq(group_id.gsub("/", "."))
    end
  end
end
