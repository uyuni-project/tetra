# encoding: UTF-8

require "spec_helper"

describe Tetra::Scriptable do
  include Tetra::Mockers

  before(:each) do
    create_mock_project

    @project.from_directory do
      File.open("history", "w") do |io|
        io.puts "some earlier command"
        io.puts "tetra dry-run --unwanted-options"
        io.puts "cd somewhere significant"
        io.puts "tetra mvn --options"
        io.puts "tetra finish -a"
        io.puts "some later command"
      end

      FileUtils.mkdir_p(File.join("src", "test-package"))
      @project.dry_run
    end

    mock_maven_executable
  end

  after(:each) do
    delete_mock_project
  end

  describe "#generate_build_script" do
    it "generates a build script from the history" do
      @project.from_directory do
        @package = Tetra::BuiltPackage.new(@project)
        @package.to_script("history")

        lines = File.readlines(File.join("packages", "test-project", "build.sh"))

        expect(lines).to include("#!/bin/bash\n")
        expect(lines).to include("cd somewhere significant\n")
        expect(lines).to include("$PROJECT_PREFIX/kit/mvn/bin/mvn -Dmaven.repo.local=$PROJECT_PREFIX/kit/m2 " \
          "-s$PROJECT_PREFIX/kit/m2/settings.xml -o --options\n"
        )

        expect(lines).not_to include("some earlier command\n")
        expect(lines).not_to include("tetra dry-run --unwanted-options\n")
        expect(lines).not_to include("tetra dry-run --unwanted-options\n")
        expect(lines).not_to include("tetra finish -a\n")
        expect(lines).not_to include("some later command\n")
      end
    end
  end

  def mock_maven_executable
    Dir.chdir(@project_path) do
      @bin_dir = File.join("kit", "mvn", "bin")
      FileUtils.mkdir_p(@bin_dir)
      @maven_executable = File.join(@bin_dir, "mvn")
      File.open(@maven_executable, "w") { |io| io.puts "echo $0 $*>test_out" }
      File.chmod(0777, @maven_executable)
    end
  end
end
