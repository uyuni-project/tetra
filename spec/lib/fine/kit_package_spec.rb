# frozen_string_literal: true

require "spec_helper"

describe Tetra::KitPackage do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
  end

  after(:each) do
    delete_mock_project
  end

  let(:instance) { Tetra::KitPackage.new(@project) }
  let(:package_name) { instance.name }

  describe "#to_spec" do
    it "generates a specfile" do
      expect(instance.to_spec).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(File.join("packages", package_name, "#{package_name}.spec"))

        expect(spec_lines).to include("Conflicts:      otherproviders(tetra-kit)\n")
        expect(spec_lines).to include("Provides:       tetra-kit\n")
      end
    end
  end
end
