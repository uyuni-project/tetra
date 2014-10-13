# encoding: UTF-8

require "spec_helper"

describe Tetra::Kit do
  include Tetra::Mockers

  before(:each) do
    create_mock_project

    @project.dry_run
    @project.finish(false)

    @kit = Tetra::Kit.new(@project)
  end

  after(:each) do
    delete_mock_project
  end

  describe "#maven_kit_items" do
    it "finds binary packages" do
      @project.from_directory(File.join("kit", "m2")) do
        maven_kit_item_path = File.join(".", "com", "company",
                                        "project", "artifact", "1.0")
        FileUtils.mkdir_p(maven_kit_item_path)

        expected_source_paths = [
          File.join(maven_kit_item_path, "artifact-1.0.jar"),
          File.join(maven_kit_item_path, "artifact-1.0.pom"),
          File.join(maven_kit_item_path, "artifact-1.0.sha1")
        ]

        expected_source_paths.each do |file|
          FileUtils.touch(file)
        end

        actual_maven_kit_item = @kit.maven_kit_items.first
        expect(actual_maven_kit_item.source_paths.sort).to eql(expected_source_paths)
      end
    end
  end

  describe "#jar_kit_items" do
    it "finds binary packages" do
      @project.from_directory(File.join("kit", "jars")) do
        FileUtils.touch("test1.jar")
      end

      actual_jar_kit_item = @kit.jar_kit_items.first
      expect(actual_jar_kit_item.source_paths).to eql([Pathname.new("test1.jar")])
    end
  end

  describe "#glue_kit_items" do
    it "finds binary packages" do
      @project.from_directory(File.join("kit")) do
        FileUtils.touch(File.join("jars", "test1.jar"))
        FileUtils.touch("test2.jar")
      end

      actual_glue_kit_items = @kit.glue_kit_items(@kit.jar_kit_items).first
      expect(actual_glue_kit_items.source_paths).not_to include(Pathname.new("test1.jar"))
      expect(actual_glue_kit_items.source_paths).to include(Pathname.new("test2.jar"))
    end
  end
end
