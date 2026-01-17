# frozen_string_literal: true

require "spec_helper"

describe Tetra::Package do
  include Tetra::Mockers

  before(:each) do
    create_mock_project

    Dir.chdir(@project_path) do
      FileUtils.mkdir_p(File.join("packages", "test-project"))
      FileUtils.touch(File.join("packages", "test-project", "test-project-4.0.tar.gz"))
    end

    @project.dry_run
    Dir.chdir(@project_path) do
      FileUtils.touch(File.join("kit", "jars", "test.jar"))
    end
    @project.finish([])

    @project.from_directory do
      FileUtils.mkdir_p(File.join("src", "out"))
      (1..5).each do |i|
        FileUtils.touch(File.join("src", "test#{i}.java"))
      end
      @project.dry_run

      (1..5).each do |i|
        FileUtils.touch(File.join("src", "test#{i}.class"))
      end

      (1..5).each do |i|
        FileUtils.touch(File.join("src", "out", "test#{i}.jar"))
      end

      @project.finish([])
    end

    FileUtils.copy(File.join("spec", "data", "nailgun", "pom.xml"), @project_path)

    patches = @project.write_source_patches
    @package = Tetra::Package.new(@project, File.join(@project_path, "pom.xml"), "*.jar", patches)
  end

  after(:each) do
    delete_mock_project
  end

  describe "#to_spec" do
    it "generates the first version" do
      @package.to_spec

      @project.from_directory do
        spec_lines = File.readlines(File.join("packages", "test-project", "test-project.spec"))

        expect(spec_lines).to include("Name:           test-project\n")
        expect(spec_lines).to include("License:        The Apache Software License, Version 2.0\n")
        expect(spec_lines).to include("Summary:        Nailgun is a client, protocol, and server for running Java\n")
        expect(spec_lines).to include("URL:            http://martiansoftware.com/nailgun\n")
        expect(spec_lines).to include("Source0:        test-project-4.0.tar.gz\n")
        expect(spec_lines).to include("BuildRequires:  test-project-kit == #{@project.version}\n")
        expect(spec_lines).to include("Provides:       mvn(com.martiansoftware:nailgun-server) == 0.9.1\n")
        expect(spec_lines).to include("Provides:       mvn(com.martiansoftware:nailgun-examples) == 0.9.1\n")
        expect(spec_lines).to include("cp -a out/test3.jar %{buildroot}%{_javadir}/test3.jar\n")
      end
    end
  end

  describe "#cleanup_description" do
    it "cleans up a simple description" do
      expect(@package.cleanup_description("Simple description.", 50)).to eq("Simple description")
    end

    it "removes newlines and extra spaces" do
      desc = "Line one.\n\nLine two  with   spaces."
      expect(@package.cleanup_description(desc, 100)).to eq("Line one. Line two with spaces")
    end

    it "truncates long descriptions" do
      desc = "This is a very long description that should be truncated here."
      # Truncate at 46 chars: "This is a very long description that should be"
      # The logic removes " be" because it ends in letters (assumed cut-off)
      expect(@package.cleanup_description(desc, 46)).to eq("This is a very long description that should")
    end

    it "removes trailing dots (ReDoS fix check)" do
      expect(@package.cleanup_description("Description...", 50)).to eq("Description")
      expect(@package.cleanup_description("Description..........", 50)).to eq("Description")
    end

    it "handles cut-off words" do
      # "This is a descrip" -> "This is a"
      expect(@package.cleanup_description("This is a description", 17)).to eq("This is a")
    end
  end
end
