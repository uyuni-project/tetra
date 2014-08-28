# encoding: UTF-8

require "spec_helper"

describe Tetra::BinaryPackage do
  let(:group_id) { "com/company/project" }
  let(:artifact_id) { "artifact" }
  let(:version) { "1.0" }
  let(:dir) { File.join(group_id, artifact_id, version) }
  let(:pom) { File.join(dir, "#{artifact_id}-#{version}.pom") }
  let(:binary_package) { Tetra::BinaryPackage.new(pom, File.join(dir, "pom.xml", [])) }

  describe "#group_id" do
    it "returns the group id" do
      expect(binary_package.group_id).to eq(group_id.gsub("/", "."))
    end
  end
end
