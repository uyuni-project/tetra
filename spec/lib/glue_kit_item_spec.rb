# encoding: UTF-8

require "spec_helper"

describe Tetra::GlueKitItem do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
  end

  after(:each) do
    delete_mock_project
  end

  let(:instance) { Tetra::GlueKitItem.new(@project, []) }

  describe "#to_spec" do
    it "generates a specfile" do
      expect(instance.to_spec).to be_truthy

      @project.from_directory do
        package_name = instance.package_name
        spec_lines = File.readlines(File.join("packages", "kit", package_name, "#{package_name}.spec"))

        expect(spec_lines).to include("Conflicts:      otherproviders(tetra-glue)\n")
        expect(spec_lines).to include("Provides:       tetra-glue == test-project-0\n")
      end
    end
  end
end
