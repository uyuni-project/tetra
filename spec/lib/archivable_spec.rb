# encoding: UTF-8

require "spec_helper"

describe Tetra::Archivable do
  include Tetra::Mockers

  # mock
  class TestArchivableClass
    include Tetra::Archivable
  end

  before(:each) do
    create_mock_project
  end

  let(:instance) { TestArchivableClass.new }

  after(:each) do
    delete_mock_project
  end

  describe "#to_archive" do
    it "generates an archive" do
      @project.from_directory("kit") do
        FileUtils.touch("kit_test")
      end

      instance._to_archive(@project, "test-package", "kit", ["*"])

      @project.from_directory do
        expect(`tar -Jtf output/test-package/test-package.tar.xz`.split).to include("kit_test")
      end
    end
  end
end
