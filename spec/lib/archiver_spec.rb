# encoding: UTF-8

require "spec_helper"

describe Tetra::Archiver do
  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Tetra::Project.init(@project_path)
    @project = Tetra::Project.new(@project_path)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  let(:archiver) { Tetra::Archiver.new(@project) }

  describe "#archive_single" do
    it "archives a list of files" do
      @project.from_directory do
        File.open("test", "w") { |io| io.puts "test content" }

        archiver.archive_single(".", "test.tar.xz")
        expect(`tar -Jtf test.tar.xz`.split).to include("test")
      end
    end
  end

  describe "#archive_kit" do
    it "archives a kit package files" do
      @project.from_directory do
        File.open(File.join("kit", "kit_test"), "w") { |io| io.puts "test content" }
      end
      @project.finish(false)

      archiver.archive_kit
      @project.from_directory do
        expect(`tar -Jtf output/test-project-kit/test-project-kit.tar.xz`.split).to include("kit_test")
      end
    end
  end

  describe "#archive_package" do
    it "archives a package files" do
      @project.from_directory do
        Dir.mkdir(File.join("src", "package-name"))
        File.open(File.join("src", "package-name", "src_test"), "w") { |io| io.puts "test content" }
      end
      @project.finish(false)

      archiver.archive_package "package-name"
      @project.from_directory do
        expect(`tar -Jtf output/package-name/package-name.tar.xz`.split).to include("src_test")
      end
    end
  end
end
