# encoding: UTF-8

require 'spec_helper'

describe Gjp::Archiver do
  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Gjp::Project.init(@project_path)
    @project = Gjp::Project.new(@project_path)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  let(:archiver) { Gjp::Archiver.new(@project) }

  describe "#archive" do
    it "archives a list of files" do
      @project.from_directory do
        File.open("test", "w") { |io| io.puts "test content" }

        archiver.archive ".", "test.tar.xz"
        `tar -Jtf test.tar.xz`.split.should include("test")
      end
    end
  end

  describe "#archive_kit" do
    it "archives a kit package files" do
      @project.from_directory do
        File.open(File.join("kit","kit_test"), "w") { |io| io.puts "test content" }
      end
      @project.finish

      archiver.archive_kit
      @project.from_directory do
        `tar -Jtf archives/test-project-kit.tar.xz`.split.should include("kit_test")
      end
    end
  end

  describe "#archive_package" do
    it "archives a package files" do
      @project.from_directory do
        Dir.mkdir(File.join("src", "package-name"))
        File.open(File.join("src", "package-name", "src_test"), "w") { |io| io.puts "test content" }
      end
      @project.finish

      archiver.archive_package "package-name"
      @project.from_directory do
        `tar -Jtf archives/package-name.tar.xz`.split.should include("src_test")
      end
    end
  end
end
