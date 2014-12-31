# encoding: UTF-8

require "spec_helper"

describe Tetra::Kit do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
  end

  after(:each) do
    delete_mock_project
  end

  let(:instance) { Tetra::Kit.new(@project) }
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

  describe "#to_archive" do
    it "generates an archive" do
      @project.from_directory(File.join("kit", "m2")) do
        FileUtils.touch("kit.content")
      end

      expected_filename = File::SEPARATOR + "#{package_name}.tar.xz"
      expect(instance.to_archive).to end_with(expected_filename)

      @project.from_directory do
        contents = `tar --list -f packages/#{package_name}/#{package_name}.tar.xz`.split
        expect(contents).to include("m2/kit.content")
      end
    end
  end
end
