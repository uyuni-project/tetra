# encoding: UTF-8

require "spec_helper"

describe Tetra::Scriptable do
  include Tetra::Mockers

  before(:each) do
    create_mock_project

    @project.from_directory do
      FileUtils.mkdir_p(File.join("src", "test-package"))
      @project.dry_run

      history = ["tetra dry-run start --unwanted-options",
                 "cd somewhere significant",
                 "mvn --options",
                 "tetra dry-run finish -a"
                ]

      @project.finish(history)
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
        @package.to_script

        lines = File.readlines(File.join("packages", "test-project", "build.sh"))

        expect(lines).to include("#!/bin/bash\n")
        expect(lines).to include("cd somewhere significant\n")
        expect(lines).to include("mvn --options\n")
        expect(lines).to include("alias mvn='$PROJECT_PREFIX/kit/mvn/bin/mvn \
-Dmaven.repo.local=$PROJECT_PREFIX/kit/m2 --settings $PROJECT_PREFIX/kit/m2/settings.xml \
--strict-checksums -o'\n"
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
