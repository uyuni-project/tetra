# encoding: UTF-8

require "spec_helper"

describe Tetra::Project do
  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Tetra::Project.init(@project_path)
    @project = Tetra::Project.new(@project_path)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  describe "#project?"  do
    it "checks if a directory is a tetra project or not" do
      expect(Tetra::Project.project?(@project_path)).to be_truthy
      expect(Tetra::Project.project?(File.join(@project_path, ".."))).to be_falsey
    end
  end

  describe "#find_project_dir"  do
    it "recursively the parent project directory" do
      expanded_path = File.expand_path(@project_path)
      expect(Tetra::Project.find_project_dir(expanded_path)).to eq expanded_path
      expect(Tetra::Project.find_project_dir(File.expand_path("src", @project_path))).to eq expanded_path
      expect(Tetra::Project.find_project_dir(File.expand_path("kit", @project_path))).to eq expanded_path

      expect do
        expect(Tetra::Project.find_project_dir(File.expand_path("..", @project_path))).to raise_error
      end.to raise_error(Tetra::NoProjectDirectoryError)
    end
  end

  describe ".get_package_name"  do
    it "raises an error with a directory outside a tetra project" do
      expect do
        @project.get_package_name("/")
      end.to raise_error(Tetra::NoPackageDirectoryError)
    end

    it "raises an error with a tetra project directory" do
      expect do
        @project.get_package_name(@project_path)
      end.to raise_error(Tetra::NoPackageDirectoryError)
    end

    it "raises an error with a tetra kit directory" do
      expect do
        @project.get_package_name(File.join(@project_path, "kit"))
      end.to raise_error(Tetra::NoPackageDirectoryError)
    end

    it "raises an error with a tetra src directory" do
      expect do
        @project.get_package_name(File.join(@project_path, "src"))
      end.to raise_error(Tetra::NoPackageDirectoryError)
    end

    it "raises an error with a nonexisting package directory" do
      expect do
        @project.get_package_name(File.join(@project_path, "src", "test_package"))
      end.to raise_error(Tetra::NoPackageDirectoryError)
    end

    it "returns the package on an existing package directory" do
      FileUtils.mkdir_p(File.join(@project_path, "src", "test_package"))
      expect(@project.get_package_name(File.join(@project_path, "src", "test_package"))).to eq "test_package"
    end

    it "returns the package on an existing package subdirectory" do
      FileUtils.mkdir_p(File.join(@project_path, "src", "test_package", "subdir1"))
      expect(@project.get_package_name(File.join(@project_path, "src", "test_package", "subdir1"))).to eq "test_package"
    end

    it "returns the package on an existing package subsubdirectory" do
      FileUtils.mkdir_p(File.join(@project_path, "src", "test_package", "subdir1", "subdir2"))
      expect(@project.get_package_name(File.join(@project_path, "src", "test_package", "subdir1", "subdir2")))
        .to eq "test_package"
    end
  end

  describe "full_path" do
    it "returns the project's full path" do
      expect(@project.full_path).to eq File.expand_path(@project_path)
    end
  end

  describe "#init" do
    it "inits a new project" do
      kit_path = File.join(@project_path, "kit")
      expect(Dir.exist?(kit_path)).to be_truthy

      src_path = File.join(@project_path, "src")
      expect(Dir.exist?(src_path)).to be_truthy
    end
  end

  describe "#dry_running?" do
    it "checks if a project is dry running" do
      @project.from_directory do
        expect(@project.dry_running?).to be_falsey
        @project.dry_run
        expect(@project.dry_running?).to be_truthy
        @project.finish(false)
        expect(@project.dry_running?).to be_falsey
      end
    end
  end

  describe "#take_snapshot" do
    it "commits the project contents to git for later use" do
      @project.from_directory do
        `touch kit/test`

        @project.take_snapshot "test", :revertable

        expect(`git rev-list --all`.split("\n").length).to eq 2
        expect(@project.latest_tag(:revertable)).to eq "revertable_1"
      end
    end
  end

  describe "#finish" do
    it "ends the current dry-run phase after a successful build" do
      @project.from_directory do
        Dir.mkdir("src/abc")
        `echo A > src/abc/test`
      end

      expect(@project.finish(true)).to be_falsey
      expect(@project.finish(false)).to be_falsey

      expect(@project.dry_run).to be_truthy

      @project.from_directory do
        `echo B > src/abc/test`
        `touch src/abc/test2`
      end

      expect(@project.finish(false)).to be_truthy
      expect(@project.dry_running?).to be_falsey

      @project.from_directory do
        expect(`git rev-list --all`.split("\n").length).to eq 4
        expect(File.read("src/abc/test")).to eq "A\n"

        expect(`git diff-tree --no-commit-id --name-only -r HEAD~`.split("\n")).to include("src/abc/test2")
        expect(File.exist?("src/abc/test2")).to be_falsey
      end
    end
    it "ends the current dry-run phase after a failed build" do
      @project.from_directory do
        Dir.mkdir("src/abc")
        `echo A > src/abc/test`
        `echo A > kit/test`
      end

      expect(@project.finish(true)).to be_falsey
      expect(@project.finish(false)).to be_falsey

      expect(@project.dry_run).to be_truthy

      @project.from_directory do
        `echo B > src/abc/test`
        `touch src/abc/test2`
        `echo B > kit/test`
        `touch kit/test2`
      end

      expect(@project.finish(true)).to be_truthy
      expect(@project.dry_running?).to be_falsey

      @project.from_directory do
        expect(`git rev-list --all`.split("\n").length).to eq 2
        expect(File.read("src/abc/test")).to eq "A\n"
        expect(File.exist?("src/abc/test2")).to be_falsey

        expect(File.read("kit/test")).to eq "A\n"
        expect(File.exist?("kit/test2")).to be_falsey
      end
    end
  end

  describe "#dry_run" do
    it "starts a dry running phase" do
      expect(@project.finish(false)).to be_falsey

      @project.from_directory do
        `touch src/test`
      end

      @project.from_directory("src") do
        expect(@project.dry_run).to be_truthy
      end

      @project.from_directory do
        expect(@project.dry_running?).to be_truthy
        expect(`git rev-list --all`.split("\n").length).to eq 2
        expect(`git diff-tree --no-commit-id --name-only -r HEAD`.split("\n")).to include("src/test")
        expect(`git cat-file tag tetra_dry_run_started_1 | tail -1`).to include("src")
      end
    end
  end

  describe "#get_produced_files" do
    it "gets a list of produced files" do
      @project.from_directory do
        Dir.mkdir("src/abc")
        `echo A > src/abc/added_outside_dry_run`
      end

      expect(@project.dry_run).to be_truthy
      @project.from_directory do
        `echo A > src/abc/added_in_first_dry_run`
        `echo A > src/added_outside_directory`
      end
      expect(@project.finish(false)).to be_truthy

      expect(@project.dry_run).to be_truthy
      @project.from_directory do
        `echo A > src/abc/added_in_second_dry_run`
      end
      expect(@project.finish(false)).to be_truthy

      list = @project.get_produced_files("abc")
      expect(list).to include("added_in_first_dry_run")
      expect(list).to include("added_in_second_dry_run")

      expect(list).not_to include("added_outside_dry_run")
      expect(list).not_to include("added_outside_directory")
    end
  end

  describe "#purge_jars" do
    it "moves jars in kit/jars" do
      @project.from_directory do
        `echo "jarring" > src/test.jar`
      end
      expect(@project.finish(false)).to be_falsey

      @project.purge_jars

      @project.from_directory do
        expect(File.symlink?(File.join("src", "test.jar"))).to be_truthy
        expect(File.readlink(File.join("src", "test.jar"))).to eq "../kit/jars/test.jar"
        expect(File.readlines(File.join("kit", "jars", "test.jar"))).to include("jarring\n")
      end
    end
  end
end
