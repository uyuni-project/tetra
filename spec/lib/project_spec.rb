# encoding: UTF-8

require 'spec_helper'

describe Gjp::Project do
  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Gjp::Project.init(@project_path)
    @project = Gjp::Project.new(@project_path)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  describe "#is_project"  do
    it "checks if a directory is a gjp project or not" do
      Gjp::Project.is_project(@project_path).should be_true    
      Gjp::Project.is_project(File.join(@project_path, "..")).should be_false
    end
  end

  describe "#find_project_dir"  do
    it "recursively the parent project directory" do
      expanded_path = File.expand_path(@project_path)
      Gjp::Project.find_project_dir(expanded_path).should eq expanded_path
      Gjp::Project.find_project_dir(File.expand_path("src", @project_path)).should eq expanded_path
      Gjp::Project.find_project_dir(File.expand_path("kit", @project_path)).should eq expanded_path

      expect {
        Gjp::Project.find_project_dir(File.expand_path("..", @project_path)).should raise_error
      }.to raise_error(Gjp::NotGjpDirectoryException)
    end
  end

  describe ".get_package_name"  do
    it "raises an error with a directory outside a gjp project" do
      expect {
        @project.get_package_name("/")
      }.to raise_error(Gjp::NoPackageDirectoryException)
    end

    it "raises an error with a gjp project directory" do
      expect {
        @project.get_package_name(@project_path)
      }.to raise_error(Gjp::NoPackageDirectoryException)
    end

    it "raises an error with a gjp kit directory" do
      expect {
        @project.get_package_name(File.join(@project_path, "kit"))
      }.to raise_error(Gjp::NoPackageDirectoryException)
    end

    it "raises an error with a gjp src directory" do
      expect {
        @project.get_package_name(File.join(@project_path, "src"))
      }.to raise_error(Gjp::NoPackageDirectoryException)
    end

    it "raises an error with a nonexisting package directory" do
      expect {
        @project.get_package_name(File.join(@project_path, "src", "test_package"))
      }.to raise_error(Gjp::NoPackageDirectoryException)
    end

    it "returns the package on an existing package directory" do
      FileUtils.mkdir_p(File.join(@project_path, "src", "test_package"))
      @project.get_package_name(File.join(@project_path, "src", "test_package")).should eq "test_package"
    end

    it "returns the package on an existing package subdirectory" do
      FileUtils.mkdir_p(File.join(@project_path, "src", "test_package", "subdir1"))
      @project.get_package_name(File.join(@project_path, "src", "test_package", "subdir1")).should eq "test_package"
    end

    it "returns the package on an existing package subsubdirectory" do
      FileUtils.mkdir_p(File.join(@project_path, "src", "test_package", "subdir1", "subdir2"))
      @project.get_package_name(File.join(@project_path, "src", "test_package", "subdir1", "subdir2")).should eq "test_package"
    end
  end

  describe "full_path" do
    it "returns the project's full path" do
      @project.full_path.should eq File.expand_path(@project_path)
    end
  end

  describe "#init" do
    it "inits a new project" do
      kit_path = File.join(@project_path, "kit")
      Dir.exists?(kit_path).should be_true

      src_path = File.join(@project_path, "src")
      Dir.exists?(src_path).should be_true
    end
  end

  describe "#is_dry_running" do
    it "checks if a project is dry running" do
      @project.from_directory do
        @project.is_dry_running.should be_false
        @project.dry_run
        @project.is_dry_running.should be_true
        @project.finish(false)
        @project.is_dry_running.should be_false
      end
    end
  end

  describe "#take_snapshot" do
    it "commits the project contents to git for later use" do
      @project.from_directory do
        `touch kit/test`

         @project.take_snapshot "test", :revertable

        `git rev-list --all`.split("\n").length.should eq 2
         @project.latest_tag(:revertable).should eq "revertable_1"
      end
    end
  end
  
  describe "#finish" do
    it "ends the current dry-run phase after a successful build" do
      @project.from_directory do
        Dir.mkdir("src/abc")
        `echo A > src/abc/test`
      end

      @project.finish(true).should be_false
      @project.finish(false).should be_false

      @project.dry_run.should be_true

      @project.from_directory do
        `echo B > src/abc/test`
        `touch src/abc/test2`
      end

      @project.finish(false).should be_true
      @project.is_dry_running.should be_false

      @project.from_directory do
        `git rev-list --all`.split("\n").length.should eq 4
        File.read("src/abc/test").should eq "A\n"

        `git diff-tree --no-commit-id --name-only -r HEAD~`.split("\n").should include("src/abc/test2")
        File.exists?("src/abc/test2").should be_false
      end
    end
    it "ends the current dry-run phase after a failed build" do
      @project.from_directory do
        Dir.mkdir("src/abc")
        `echo A > src/abc/test`
        `echo A > kit/test`
      end

      @project.finish(true).should be_false
      @project.finish(false).should be_false

      @project.dry_run.should be_true

      @project.from_directory do
        `echo B > src/abc/test`
        `touch src/abc/test2`
        `echo B > kit/test`
        `touch kit/test2`
      end

      @project.finish(true).should be_true
      @project.is_dry_running.should be_false

      @project.from_directory do
        `git rev-list --all`.split("\n").length.should eq 2
        File.read("src/abc/test").should eq "A\n"
        File.exists?("src/abc/test2").should be_false

        File.read("kit/test").should eq "A\n"
        File.exists?("kit/test2").should be_false
      end
    end
  end

  describe "#dry_run" do
    it "starts a dry running phase" do
      @project.finish(false).should be_false

      @project.from_directory do
        `touch src/test`
      end

      @project.from_directory("src") do
        @project.dry_run.should be_true
      end

      @project.from_directory do
        @project.is_dry_running.should be_true
        `git rev-list --all`.split("\n").length.should eq 2
        `git diff-tree --no-commit-id --name-only -r HEAD`.split("\n").should include("src/test")
        `git cat-file tag gjp_dry_run_started_1 | tail -1`.should include("src")
      end
    end    
  end

  describe "#get_produced_files" do
    it "gets a list of produced files" do
      @project.from_directory do
        Dir.mkdir("src/abc")
        `echo A > src/abc/added_outside_dry_run`
      end

      @project.dry_run.should be_true
      @project.from_directory do
        `echo A > src/abc/added_in_first_dry_run`
        `echo A > src/added_outside_directory`
      end
      @project.finish(false).should be_true

      @project.dry_run.should be_true
      @project.from_directory do
        `echo A > src/abc/added_in_second_dry_run`
      end
      @project.finish(false).should be_true

      list = @project.get_produced_files("abc")
      list.should include("added_in_first_dry_run")
      list.should include("added_in_second_dry_run")

      list.should_not include("added_outside_dry_run")
      list.should_not include("added_outside_directory")
    end
  end

  describe "#purge_jars" do
    it "moves jars in kit/jars" do
      @project.from_directory do
        `echo "jarring" > src/test.jar`
      end
      @project.finish(false).should be_false

      @project.purge_jars

      @project.from_directory do
        File.symlink?(File.join("src", "test.jar")).should be_true
        File.readlink(File.join("src", "test.jar")).should eq "../kit/jars/test.jar"
        File.readlines(File.join("kit", "jars", "test.jar")).should include("jarring\n")
      end
    end
  end
end
