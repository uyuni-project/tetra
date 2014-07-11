# encoding: UTF-8

require "spec_helper"

describe Tetra::SpecGenerator do
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

    @spec_generator = Tetra::SpecGenerator.new(@project)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  describe "#generate_kit_spec" do
    it "generates the first version" do
      expect(@spec_generator.generate_kit_spec).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(File.join("output", "test-project-kit", "test-project-kit.spec"))
        expect(spec_lines).to include("Name:           test-project-kit\n")
        expect(spec_lines).to include("Version:        1\n")
        expect(spec_lines).to include("Source0:        test-project-kit.tar.xz\n")
      end
    end
    it "generates a second version" do
      expect(@spec_generator.generate_kit_spec).to be_truthy
      @project.dry_run
      Dir.chdir(@project_path) do
        test_file = File.join("kit", "test")
        File.open(test_file, "w") { |io| io.puts "changed kit content test file" }

        File.open(File.join("output", "test-project-kit", "test-project-kit.spec"), "a") do |io|
          io.write("nonconflicting line")
        end
      end
      @project.finish(false)

      expect(@spec_generator.generate_kit_spec).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(File.join("output", "test-project-kit", "test-project-kit.spec"))
        expect(spec_lines).to include("Name:           test-project-kit\n")
        expect(spec_lines).to include("Version:        2\n")
        expect(spec_lines).to include("Source0:        test-project-kit.tar.xz\n")
        expect(spec_lines).to include("nonconflicting line\n")
      end
    end
    it "generates a conflicting version" do
      expect(@spec_generator.generate_kit_spec).to be_truthy
      @project.dry_run
      Dir.chdir(@project_path) do
        test_file = File.join("kit", "test")
        File.open(test_file, "w") { |io| io.puts "changed kit content test file" }

        spec_path = File.join("output", "test-project-kit", "test-project-kit.spec")
        spec_contents = File.read spec_path

        spec_contents.gsub!(/^Version:.*$/, "CONFLICTING!")

        File.open(spec_path, "w+") do |io|
          io.write(spec_contents)
        end
      end
      @project.finish(false)

      expect(@spec_generator.generate_kit_spec).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(File.join("output", "test-project-kit", "test-project-kit.spec"))
        expect(spec_lines).to include("Name:           test-project-kit\n")
        expect(spec_lines).to include("Source0:        test-project-kit.tar.xz\n")
        expect(spec_lines).to include("<<<<<<< newly generated\n")
        expect(spec_lines).to include("Version:        2\n")
        expect(spec_lines).to include("=======\n")
        expect(spec_lines).to include("CONFLICTING!\n")
        expect(spec_lines).to include(">>>>>>> user edited\n")
      end
    end
  end

  describe "#generate_package_spec" do
    it "generates the first version" do

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
      @spec_generator.generate_package_spec "test", File.join(@project_path, "pom.xml"), "*.jar"

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
end
