# encoding: UTF-8

require "spec_helper"

describe Tetra::Project do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
  end

  after(:each) do
    delete_mock_project
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

  describe "full_path" do
    it "returns the project's full path" do
      expect(@project.full_path).to eq File.expand_path(@project_path)
    end
  end

  describe "#template_files" do
    it "returns the list of template files without bundles" do
      expect(@project.template_files(false)).to include({"kit" => "."})
    end

    it "returns the list of template files with bundles" do
      expect(@project.template_files(true)).to include({"bundled/apache-ant-1.9.4" => "kit"})
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
        @project.finish
        expect(@project.dry_running?).to be_falsey
      end
    end
  end

  describe "#take_snapshot" do
    it "commits the project contents to git for later use" do
      @project.from_directory do
        FileUtils.touch(File.join("kit", "test"))

        # check that gitignore files are moved correctly
        File.open(File.join("src", ".gitignore"), "w") do |file|
          file.write "file"
        end

        @project.take_snapshot("test", :revertable)

        files = `git ls-tree --name-only -r HEAD`.split("\n")
        expect(files).to include("src/.gitignore_disabled_by_tetra")

        expect(`git rev-list --all`.split("\n").length).to eq 2
        expect(@project.latest_tag(:revertable)).to eq "revertable_1"
      end
    end
  end

  describe "#finish" do
    it "ends the current dry-run phase after a successful build" do
      @project.from_directory do
        File.open(File.join("src", "test"), "w") { |f| f.write("A") }
      end

      expect(@project.abort).to be_falsey
      expect(@project.finish).to be_falsey

      expect(@project.dry_run).to be_truthy

      @project.from_directory do
        File.open(File.join("src", "test"), "w") { |f| f.write("B") }
        FileUtils.touch(File.join("src", "test2"))
      end

      expect(@project.finish).to be_truthy
      expect(@project.dry_running?).to be_falsey

      @project.from_directory do
        expect(`git rev-list --all`.split("\n").length).to eq 4
        expect(File.read("src/test")).to eq "A"

        expect(`git diff-tree --no-commit-id --name-only -r HEAD~`.split("\n")).to include("src/test2")
        expect(File.exist?("src/test2")).to be_falsey
      end
    end
    it "ends the current dry-run phase after a failed build" do
      @project.from_directory do
        File.open(File.join("src", "test"), "w") { |f| f.write("A") }
        File.open(File.join("kit", "test"), "w") { |f| f.write("A") }
      end

      expect(@project.abort).to be_falsey
      expect(@project.finish).to be_falsey

      expect(@project.dry_run).to be_truthy

      @project.from_directory do
        File.open(File.join("src", "test"), "w") { |f| f.write("B") }
        FileUtils.touch(File.join("src", "test2"))
        File.open(File.join("kit", "test"), "w") { |f| f.write("B") }
        FileUtils.touch(File.join("kit", "test2"))
      end

      expect(@project.abort).to be_truthy
      expect(@project.dry_running?).to be_falsey

      @project.from_directory do
        expect(`git rev-list --all`.split("\n").length).to eq 2
        expect(File.read("src/test")).to eq "A"
        expect(File.exist?("src/test2")).to be_falsey

        expect(File.read("kit/test")).to eq "A"
        expect(File.exist?("kit/test2")).to be_falsey
      end
    end
  end

  describe "#dry_run" do
    it "starts a dry running phase" do
      expect(@project.finish).to be_falsey

      @project.from_directory do
        FileUtils.touch(File.join("src", "test"))
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

  describe "#produced_files" do
    it "gets a list of produced files" do
      @project.from_directory do
        File.open(File.join("src", "added_outside_dry_run"), "w") { |f| f.write("A") }
      end

      expect(@project.dry_run).to be_truthy
      @project.from_directory do
        File.open(File.join("src", "added_in_first_dry_run"), "w") { |f| f.write("A") }
        File.open("added_outside_directory", "w") { |f| f.write("A") }
      end
      expect(@project.finish).to be_truthy

      expect(@project.dry_run).to be_truthy
      @project.from_directory do
        File.open(File.join("src", "added_in_second_dry_run"), "w") { |f| f.write("A") }
      end
      expect(@project.finish).to be_truthy

      list = @project.produced_files
      expect(list).to include("added_in_first_dry_run")
      expect(list).to include("added_in_second_dry_run")

      expect(list).not_to include("added_outside_dry_run")
      expect(list).not_to include("added_outside_directory")
    end
  end

  describe "#purge_jars" do
    it "moves jars in kit/jars" do
      @project.from_directory do
        File.open(File.join("src", "test.jar"), "w") { |f| f.write("jarring") }
      end
      expect(@project.finish).to be_falsey

      @project.purge_jars

      @project.from_directory do
        expect(File.symlink?(File.join("src", "test.jar"))).to be_truthy
        expect(File.readlink(File.join("src", "test.jar"))).to eq "../kit/jars/test.jar"
        expect(File.readlines(File.join("kit", "jars", "test.jar"))).to include("jarring")
      end
    end
  end
end
