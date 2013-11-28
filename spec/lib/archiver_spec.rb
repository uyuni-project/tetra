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

  describe "#archive_single" do
    it "archives a list of files" do
      @project.from_directory do
        File.open("test", "w") { |io| io.puts "test content" }

        archiver.archive_single(".", "test.tar.xz")
        `tar -Jtf test.tar.xz`.split.should include("test")
      end
    end
  end

  describe "#archive_incremental" do
    it "archives an increment of a directory" do
      @project.from_directory do
        File.open("test", "w") { |io| io.puts "test content 1" }
        File.open("test2", "w") { |io| io.puts "test content 1" }
        archiver.archive_incremental(".", ".", "test", ".tar.xz", :archive_kit)
        `tar -Jtf test.tar.xz`.split.should include("test")

        @project.take_snapshot("test archive snapshot 1", :archive_kit)

        File.open("test", "w") { |io| io.puts "test content 2" }
        File.open("test3", "w") { |io| io.puts "test content 2" }

        @project.take_snapshot("test archive snapshot 2")

        archiver.archive_incremental(".", ".", "test", ".tar.xz", :archive_kit)
        files = `tar -Jtf test_0001.tar.xz`.split

        files.should include("test")
        files.should include("test3")
        files.should_not include("test2")
      end
    end
  end

  describe "#archive_kit" do
    it "archives a kit package files, not incrementally" do
      @project.from_directory do
        File.open(File.join("kit","kit_test"), "w") { |io| io.puts "test content" }
      end
      @project.finish(false)

      archiver.archive_kit(true)
      @project.from_directory do
        `tar -Jtf output/test-project-kit/test-project-kit.tar.xz`.split.should include("kit_test")
      end
    end
    it "archives a kit package files incrementally" do
      @project.from_directory do
        File.open(File.join("kit","kit_test"), "w") { |io| io.puts "test content" }
      end
      @project.finish(false)

      archiver.archive_kit(false)
      @project.from_directory do
        `tar -Jtf output/test-project-kit/test-project-kit.tar.xz`.split.should include("kit_test")
      end

      @project.from_directory do
        File.open(File.join("kit","kit_test2"), "w") { |io| io.puts "test content" }
      end

      archiver.archive_kit(false)
      @project.from_directory do
        files = `tar -Jtf output/test-project-kit/test-project-kit_0001.tar.xz`.split
        files.should include("kit_test2")
        files.should_not include("kit_test")
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
        `tar -Jtf output/package-name/package-name.tar.xz`.split.should include("src_test")
      end
    end
  end
end
