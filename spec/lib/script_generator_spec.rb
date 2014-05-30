# encoding: UTF-8

require "spec_helper"

describe Gjp::ScriptGenerator do
  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Gjp::Project.init(@project_path)
    @project = Gjp::Project.new(@project_path)

    @project.from_directory do
      File.open("history", "w") do |io|
        io.puts "some earlier command"
        io.puts "gjp dry-run --unwanted-options"
        io.puts "cd somewhere significant"
        io.puts "gjp mvn --options"
        io.puts "gjp finish -a"
        io.puts "some later command"
      end

      FileUtils.mkdir_p(File.join("src", "test-package"))
      @project.dry_run

      @generator = Gjp::ScriptGenerator.new(@project, "history")
    end

    mock_maven_executable
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  describe "#generate_build_script" do
    it "generates a build script from the history" do
      @project.from_directory do
        @generator.generate_build_script("test-package")

        lines = File.readlines(File.join("src", "test-package", "build.sh"))

        lines.should include("#!/bin/bash\n")
        lines.should include("cd somewhere significant\n")
        lines.should include("$PROJECT_PREFIX/kit/mvn/bin/mvn -Dmaven.repo.local=$PROJECT_PREFIX/kit/m2 " \
          "-s$PROJECT_PREFIX/kit/m2/settings.xml -o --options\n"
        )

        lines.should_not include("some earlier command\n")
        lines.should_not include("gjp dry-run --unwanted-options\n")
        lines.should_not include("gjp dry-run --unwanted-options\n")
        lines.should_not include("gjp finish -a\n")
        lines.should_not include("some later command\n")
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
