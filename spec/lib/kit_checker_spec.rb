# encoding: UTF-8

require "spec_helper"
require "rubygems"
require "zip"

describe Gjp::KitChecker do
  include Gjp::Mockers

  before(:each) do
    create_mock_project
    @kit_checker = Gjp::KitChecker.new(@project)
  end

  after(:each) do
    delete_mock_project
  end

  describe "#kit_file_paths"  do
    it "returns an array of paths found in kit" do
      @project.from_directory("kit") do
        FileUtils.touch("top_level")
        FileUtils.mkdir_p("directory")
        FileUtils.touch(File.join("directory", "in_directory"))
        Zip::File.open("zipped.zip", Zip::File::CREATE) do |zipfile|
          Dir[File.join("directory", "**", "**")].each do |file|
            zipfile.add(file.sub("/directory", ""), file)
          end
        end
      end

      all_files = @kit_checker.kit_file_paths

      all_files.should include ["top_level", nil]
      all_files.should_not include ["directory", nil]
      all_files.should include ["directory/in_directory", nil]
      all_files.should include ["zipped.zip", nil]
      all_files.should include ["directory/in_directory", "zipped.zip"]
    end
  end

  describe "#source_class_names"  do
    it "distills source class names in kit" do
      all_files = [
        ["path/to/ClassOne.java", nil],
        ["path/to/ClassTwo.java", "path/to/archive.jar"],
        ["ClassThree.java", "another_archive.jar"],
        ["path/to/CompiledClass.class", "yet_another.jar"],
      ]

      class_names = @kit_checker.source_class_names(all_files)

      class_names.should include "path.to.ClassOne"
      class_names.should include "path.to.ClassTwo"
      class_names.should include "ClassThree"
      class_names.should_not include "path.to.CompiledClass"
    end
  end

  describe "#compiled_classes"  do
    it "distills source class names in kit" do
      all_files = [
        ["path/to/ClassOne.class", nil],
        ["path/to/ClassTwo.class", "path/to/archive.jar"],
        ["ClassThree.class", "another_archive.jar"],
        ["path/to/SourceClass.java", "yet_another.jar"],
      ]

      classes = @kit_checker.compiled_classes(all_files)

      classes[nil].should include "path.to.ClassOne"
      classes["path/to/archive.jar"].should include "path.to.ClassTwo"
      classes["another_archive.jar"].should include "ClassThree"
      classes["yet_another.jar"].should be_nil
    end
  end

  describe "#unsourced_archives" do
    it "returns a list of jars wich source files are missing" do
      @project.from_directory("kit") do
        FileUtils.mkdir_p("package1")
        FileUtils.touch(File.join("package1", "UnsourcedClass.class"))

        FileUtils.mkdir_p("package2")
        FileUtils.touch(File.join("package2", "SourcedClass.java"))
        Zip::File.open("zipped-source-2.jar", Zip::File::CREATE) do |zipfile|
          Dir[File.join("package2", "**", "**")].each do |file|
            zipfile.add(file.sub("/package2", ""), file)
          end
        end
        FileUtils.rm(File.join("package2", "SourcedClass.java"))
        FileUtils.touch(File.join("package2", "SourcedClass.class"))
        Zip::File.open("zipped-2.jar", Zip::File::CREATE) do |zipfile|
          Dir[File.join("package2", "**", "**")].each do |file|
            zipfile.add(file.sub("/package2", ""), file)
          end
        end

        FileUtils.mkdir_p("package3")
        FileUtils.touch(File.join("package3", "SourcedSameArchive.java"))
        FileUtils.touch(File.join("package3", "SourcedSameArchive.class"))
        Zip::File.open("zipped-3.zip", Zip::File::CREATE) do |zipfile|
          Dir[File.join("package3", "**", "**")].each do |file|
            zipfile.add(file.sub("/package3", ""), file)
          end
        end
      end

      unsourced = @kit_checker.unsourced_archives
      unsourced.length().should eq 1

      unsourced.first[:archive].should be_nil
      unsourced.first[:class_names].should include "package1.UnsourcedClass"
      unsourced.first[:class_names].should include "package2.SourcedClass"
      unsourced.first[:class_names].should include "package3.SourcedSameArchive"
      unsourced.first[:unsourced_class_names].should include "package1.UnsourcedClass"
    end
  end
end
