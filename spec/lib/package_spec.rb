# encoding: UTF-8

require "spec_helper"

describe Tetra::Package do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
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
        expect(spec_lines).to include("Url:            http://martiansoftware.com/nailgun\n")
        expect(spec_lines).to include("BuildRequires:  test-project-kit == #{@project.version}\n")
        expect(spec_lines).to include("Provides:       mvn(com.martiansoftware:nailgun-all) == 0.9.1\n")
        expect(spec_lines).to include("cp -a out/test3.jar %{buildroot}%{_javadir}/test3.jar\n")
      end
    end
  end
end
