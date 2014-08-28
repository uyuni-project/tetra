# encoding: UTF-8

require "spec_helper"

describe Tetra::Package do
  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Tetra::Project.init(@project_path)
    @project = Tetra::Project.new(@project_path)

    @project.dry_run
    Dir.chdir(@project_path) do
      test_file = File.join("kit", "test")
      File.open(test_file, "w") { |io| io.puts "kit content test file" }
    end
    @project.finish(false)

    @project.from_directory do
      FileUtils.mkdir_p File.join("src", "test", "out")
      (1..5).each do |i|
        `touch src/test/test#{i}.java`
      end
      @project.dry_run

      (1..5).each do |i|
        `touch src/test/test#{i}.class`
      end

      (1..5).each do |i|
        `touch src/test/out/test#{i}.jar`
      end

      @project.finish(false)
    end

    FileUtils.copy(File.join("spec", "data", "nailgun", "pom.xml"), @project_path)

    @package = Tetra::Package.new(@project, "test", File.join(@project_path, "pom.xml"), "*.jar")
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  describe "#to_spec" do
    it "generates the first version" do
      @package.to_spec

      @project.from_directory do
        spec_lines = File.readlines(File.join("output", "test", "test.spec"))
        expect(spec_lines).to include("Name:           test\n")
        expect(spec_lines).to include("License:        The Apache Software License, Version 2.0\n")
        expect(spec_lines).to include("Summary:        Nailgun is a client, protocol, and server for running Java\n")
        expect(spec_lines).to include("Url:            http://martiansoftware.com/nailgun\n")
        expect(spec_lines).to include("BuildRequires:  #{@project.name}-kit >= 2\n")
        expect(spec_lines).to include("Provides:       mvn(com.martiansoftware:nailgun-all) == 0.9.1\n")
        expect(spec_lines).to include("cp -a out/test3.jar %{buildroot}%{_javadir}/test3.jar\n")
      end
    end
  end

  describe "#to_archive" do
    it "generates an archive" do
      @project.from_directory("src") do
        FileUtils.touch(File.join("test", "src_test"))
      end
      @project.finish(false)

      @package.to_archive
      @project.from_directory do
        expect(`tar -Jtf output/test/test.tar.xz`.split).to include("src_test")
      end
    end
  end
end
