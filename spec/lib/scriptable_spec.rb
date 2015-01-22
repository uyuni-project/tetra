# encoding: UTF-8

require "spec_helper"

describe Tetra::Scriptable do
  include Tetra::Mockers

  before(:each) do
    create_mock_project

    @project.from_directory do
      File.open("history", "w") do |io|
        io.puts "some earlier command"
        io.puts "tetra dry-run start --unwanted-options"
        io.puts "cd somewhere significant"
        io.puts "tetra mvn --options"
        io.puts "tetra dry-run finish -a"
        io.puts "some later command"
      end

      FileUtils.mkdir_p(File.join("src", "test-package"))
      @project.dry_run
    end

    create_mock_executable("ant")
    create_mock_executable("mvn")
  end

  after(:each) do
    delete_mock_project
  end

  describe "#generate_build_script" do
    it "generates a build script from the history" do
      @project.from_directory do
        @package = Tetra::Package.new(@project)
        @package.to_script("history")

        lines = File.readlines(File.join("packages", "test-project", "build.sh"))

        expect(lines).to include("#!/bin/bash\n")
        expect(lines).to include("cd somewhere significant\n")
        expect(lines).to include("$PROJECT_PREFIX/kit/apache-maven-3.2.5/bin/mvn \
-Dmaven.repo.local=$PROJECT_PREFIX/kit/m2 --settings $PROJECT_PREFIX/kit/m2/settings.xml \
--strict-checksums -o --options\n"
        )

        expect(lines).not_to include("some earlier command\n")
        expect(lines).not_to include("tetra dry-run --unwanted-options\n")
        expect(lines).not_to include("tetra dry-run --unwanted-options\n")
        expect(lines).not_to include("tetra finish -a\n")
        expect(lines).not_to include("some later command\n")
      end
    end
  end
end
