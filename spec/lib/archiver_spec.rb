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

  describe "#archive_incremental" do
    it "archives an increment of a directory" do
      @project.from_directory do
        File.open("test", "w") { |io| io.puts "test content 1" }
        File.open("test2", "w") { |io| io.puts "test content 1" }
        archiver.archive_incremental(".", ".", "test", ".tar.xz", :archive_kit)
        expect(`tar -Jtf test.tar.xz`.split).to include("test")

        @project.take_snapshot("test archive snapshot 1", :archive_kit)

        File.open("test", "w") { |io| io.puts "test content 2" }
        File.open("test3", "w") { |io| io.puts "test content 2" }

        @project.take_snapshot("test archive snapshot 2")

        archiver.archive_incremental(".", ".", "test", ".tar.xz", :archive_kit)
        files = `tar -Jtf test_0001.tar.xz`.split

        expect(files).to include("test")
        expect(files).to include("test3")
        expect(files).not_to include("test2")
      end
    end
  end

  describe "#archive_kit" do
    it "archives a kit package files, not incrementally" do
      @project.from_directory do
        File.open(File.join("kit", "kit_test"), "w") { |io| io.puts "test content" }
      end
      @project.finish(false)

      archiver.archive_kit(true)
      @project.from_directory do
        expect(`tar -Jtf output/test-project-kit/test-project-kit.tar.xz`.split).to include("kit_test")
      end
    end
    it "archives a kit package files incrementally" do
      @project.from_directory do
        File.open(File.join("kit", "kit_test"), "w") { |io| io.puts "test content" }
      end
      @project.finish(false)

      archiver.archive_kit(false)
      @project.from_directory do
        expect(`tar -Jtf output/test-project-kit/test-project-kit.tar.xz`.split).to include("kit_test")
      end

      @project.from_directory do
        File.open(File.join("kit", "kit_test2"), "w") { |io| io.puts "test content" }
      end

      archiver.archive_kit(false)
      @project.from_directory do
        files = `tar -Jtf output/test-project-kit/test-project-kit_0001.tar.xz`.split
        expect(files).to include("kit_test2")
        expect(files).not_to include("kit_test")
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
