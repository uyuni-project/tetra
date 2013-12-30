# encoding: UTF-8

require "spec_helper"
require "rubygems"
require "zip/zip"

describe Gjp::KitChecker do
  include Gjp::Mockers

  before(:each) do
    create_mock_project
    @kit_checker = Gjp::KitChecker.new(@project)
  end

  after(:each) do
    delete_mock_project
  end

  describe "#each_path"  do
    it "yields a block for each file in kit, including those in archives" do
      @project.from_directory("kit") do
        FileUtils.touch("top_level")
        FileUtils.mkdir_p("directory")
        FileUtils.touch(File.join("directory","in_directory"))
        Zip::ZipFile.open("zipped.zip", Zip::ZipFile::CREATE) do |zipfile|
          Dir[File.join("directory", "**", "**")].each do |file|
            zipfile.add(file.sub("/directory", ""), file)
          end
        end
      end

      all_files = []
      @kit_checker.each_path do |archive, path|
        all_files << [archive, path]
      end

      all_files.should include [nil, "top_level"]
      all_files.should_not include [nil, "directory"]
      all_files.should include [nil, "directory/in_directory"]
      all_files.should include [nil, "zipped.zip"]
      all_files.should include ["zipped.zip", "directory/in_directory"]
    end
  end

  describe "#get_classes"  do
    it "distills source and compiled classes in kit" do
      @project.from_directory("kit") do
        FileUtils.touch("TopClass.java")
        FileUtils.mkdir_p("package")
        FileUtils.touch(File.join("package","InPackageClass.java"))
        Zip::ZipFile.open("zipped.jar", Zip::ZipFile::CREATE) do |zipfile|
          Dir[File.join("package", "**", "**")].each do |file|
            zipfile.add(file.sub("/package", ""), file)
          end
        end
        FileUtils.touch(File.join("package","OutOfArchiveClass.java"))
      end

      jars_to_classes, jars_to_sources = @kit_checker.get_classes

      jars_to_sources[nil].should include "TopClass"
      jars_to_sources["zipped.jar"].should include "package.InPackageClass"
      jars_to_sources[nil].should include "package.OutOfArchiveClass"
    end
  end

  describe "#get_unsourced" do
    it "returns a list of jars wich source files are missing" do
      @project.from_directory("kit") do
        FileUtils.mkdir_p("package1")
        FileUtils.touch(File.join("package1","UnsourcedClass.class"))

        FileUtils.mkdir_p("package2")
        FileUtils.touch(File.join("package2","SourcedClass.java"))
        Zip::ZipFile.open("zipped-source-2.jar", Zip::ZipFile::CREATE) do |zipfile|
          Dir[File.join("package2", "**", "**")].each do |file|
            zipfile.add(file.sub("/package2", ""), file)
          end
        end
        FileUtils.rm(File.join("package2","SourcedClass.java"))
        FileUtils.touch(File.join("package2","SourcedClass.class"))
        Zip::ZipFile.open("zipped-2.jar", Zip::ZipFile::CREATE) do |zipfile|
          Dir[File.join("package2", "**", "**")].each do |file|
            zipfile.add(file.sub("/package2", ""), file)
          end
        end

        FileUtils.mkdir_p("package3")
        FileUtils.touch(File.join("package3","SourcedSameArchive.java"))
        FileUtils.touch(File.join("package3","SourcedSameArchive.class"))
        Zip::ZipFile.open("zipped-3.zip", Zip::ZipFile::CREATE) do |zipfile|
          Dir[File.join("package3", "**", "**")].each do |file|
            zipfile.add(file.sub("/package3", ""), file)
          end
        end
      end

      unsourced = @kit_checker.get_unsourced

      unsourced.should include nil
      unsourced.should_not include "zipped-source-2.jar"
      unsourced.should_not include "zipped-2.jar"
      unsourced.should_not include "zipped-3.jar"
    end
  end
end
