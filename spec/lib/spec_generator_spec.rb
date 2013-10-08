# encoding: UTF-8

require 'spec_helper'

describe Gjp::SpecGenerator do
  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Gjp::Project.init(@project_path)
    @project = Gjp::Project.new(@project_path)

    @project.dry_run
    Dir.chdir(@project_path) do
      test_file = File.join("kit", "test")
      File.open(test_file, "w") { |io| io.puts "kit content test file" }
    end
    @project.finish(false)

    @spec_generator = Gjp::SpecGenerator.new(@project)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  describe "#generate_kit_spec" do
    it "generates the first version" do
      @spec_generator.generate_kit_spec.should be_true

      @project.from_directory do
        spec_lines = File.readlines(File.join("specs", "test-project-kit.spec"))
        spec_lines.should include("Name:           test-project-kit\n")
        spec_lines.should include("Version:        1\n")
        spec_lines.should include("Source0:        %{name}.tar.xz\n")
      end
    end
    it "generates a second version" do
      @spec_generator.generate_kit_spec.should be_true
      @project.dry_run
      Dir.chdir(@project_path) do
        test_file = File.join("kit", "test")
        File.open(test_file, "w") { |io| io.puts "changed kit content test file" }

        File.open(File.join("specs", "test-project-kit.spec"), "a") do |io|
          io.write("nonconflicting line")
        end
      end
      @project.finish(false)

      @spec_generator.generate_kit_spec.should be_true

      @project.from_directory do
        spec_lines = File.readlines(File.join("specs", "test-project-kit.spec"))
        spec_lines.should include("Name:           test-project-kit\n")
        spec_lines.should include("Version:        2\n")
        spec_lines.should include("Source0:        %{name}.tar.xz\n")
        spec_lines.should include("nonconflicting line\n")
      end
    end
    it "generates a conflicting version" do
      @spec_generator.generate_kit_spec.should be_true
      @project.dry_run
      Dir.chdir(@project_path) do
        test_file = File.join("kit", "test")
        File.open(test_file, "w") { |io| io.puts "changed kit content test file" }

        spec_path = File.join("specs", "test-project-kit.spec")
        spec_contents = File.read spec_path

        spec_contents.gsub! /^Version:.*$/, "CONFLICTING!"

        File.open(spec_path, "w+") do |io|
          io.write(spec_contents)
        end
      end
      @project.finish(false)

      @spec_generator.generate_kit_spec.should be_true

      @project.from_directory do
        spec_lines = File.readlines(File.join("specs", "test-project-kit.spec"))
        spec_lines.should include("Name:           test-project-kit\n")
        spec_lines.should include("Source0:        %{name}.tar.xz\n")
        spec_lines.should include("<<<<<<< newly generated\n")
        spec_lines.should include("Version:        2\n")
        spec_lines.should include("=======\n")
        spec_lines.should include("CONFLICTING!\n")
        spec_lines.should include(">>>>>>> user edited\n")
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

      @spec_generator.generate_package_spec "test", File.join("spec", "data", "nailgun", "pom.xml"), "*.jar"

      @project.from_directory do
        spec_lines = File.readlines(File.join("specs", "test.spec"))
        spec_lines.should include("Name:           test\n")
        spec_lines.should include("License:        The Apache Software License, Version 2.0\n")
        spec_lines.should include("Summary:        Nailgun is a client, protocol, and server for running Java\n")
        spec_lines.should include("Url:            http://martiansoftware.com/nailgun\n")
        spec_lines.should include("BuildRequires:  #{@project.name}-kit >= 2\n")
        spec_lines.should include("Provides:       mvn(com.martiansoftware:nailgun-all) == 0.9.1\n")
        spec_lines.should include("cp -a out/test3.jar %{buildroot}%{_javadir}/test3.jar\n")
      end
    end
  end
end
