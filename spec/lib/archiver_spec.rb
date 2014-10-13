# encoding: UTF-8

require "spec_helper"

describe Tetra::Archiver do
  include Tetra::Mockers

  # mock
  class TestArchiverClass
    include Tetra::Archiver

    attr_reader :project
    attr_reader :package_name
    attr_reader :source_dir
    attr_reader :source_paths
    attr_reader :destination_dir

    def initialize(project)
      @project = project
      @package_name = "test-package"
      @source_dir = "kit"
      @source_paths = ["*"]
      @destination_dir = "test-package"
    end
  end

  before(:each) do
    create_mock_project
  end

  let(:instance) { TestArchiverClass.new(@project) }

  after(:each) do
    delete_mock_project
  end

  describe "#to_archive" do
    it "generates an archive" do
      @project.from_directory("kit") do
        FileUtils.touch("kit_test")
      end

      instance.to_archive

      @project.from_directory do
        expect(`tar -Jtf output/test-package/test-package.tar.xz`.split).to include("kit_test")
      end
    end
  end
end
