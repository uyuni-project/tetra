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

  describe "version"  do
    it "returns no project version in case no dry-run happened" do
      expect(@project.version).to be_nil
    end

    it "returns a project version after dry-run" do
      @project.dry_run
      @project.finish
      expect(@project.version).to be
    end
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
      expect(@project.template_files(false)).to include("kit" => ".")
    end

    it "returns the list of template files with bundles" do
      expect(@project.template_files(true)).to include("bundled/apache-ant-1.9.4" => "kit")
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

  describe "#src_patched?"  do
    it "checks whether src is dirty" do
      @project.from_directory do
        @project.dry_run
        @project.finish
        expect(@project.src_patched?).to be_falsey

        FileUtils.touch(File.join("src", "test"))
        expect(@project.src_patched?).to be_truthy
      end
    end
  end

  describe "#commit_whole_directory" do
    it "commits the project contents to git for later use" do
      @project.from_directory do
        FileUtils.touch(File.join("kit", "test"))

        # check that gitignore files are moved correctly
        File.open(File.join("src", ".gitignore"), "w") do |file|
          file.write "file"
        end

        @project.commit_whole_directory(".", "test")

        files = `git ls-tree --name-only -r HEAD`.split("\n")
        expect(files).to include("src/.gitignore_disabled_by_tetra")

        expect(`git rev-list --all`.split("\n").length).to eq 2
      end
    end
  end

  describe "#finish" do
    it "ends the current dry-run phase after a successful build" do
      @project.from_directory do
        File.open(File.join("src", "test"), "w") { |f| f.write("A") }
      end

      expect(@project.dry_run).to be_truthy

      @project.from_directory do
        File.open(File.join("src", "test"), "w") { |f| f.write("B") }
        FileUtils.touch(File.join("src", "test2"))
      end

      expect(@project.finish).to be_truthy
      expect(@project.dry_running?).to be_falsey

      @project.from_directory do
        expect(`git rev-list --all`.split("\n").length).to eq 3
        expect(File.read("src/test")).to eq "A"

        expect(`git diff-tree --no-commit-id --name-only -r HEAD~`.split("\n")).to include("src/test")
        expect(File.exist?("src/test2")).to be_falsey

        expect(`git show HEAD`.split("\n").map(&:strip)).to include("tetra: file-changed: src/test")
      end
    end
    it "ends the current dry-run phase after a failed build" do
      @project.from_directory do
        File.open(File.join("src", "test"), "w") { |f| f.write("A") }
        File.open(File.join("kit", "test"), "w") { |f| f.write("A") }
      end

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
        expect(`git rev-list --all`.split("\n").length).to eq 1
        expect(File.read("src/test")).to eq "A"
        expect(File.exist?("src/test2")).to be_falsey

        expect(File.read("kit/test")).to eq "A"
        expect(File.exist?("kit/test2")).to be_falsey
      end
    end
  end

  describe "#dry_run" do
    it "starts a dry running phase" do
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
      expect(list).to include("added_in_second_dry_run")

      expect(list).not_to include("added_in_first_dry_run")
      expect(list).not_to include("added_outside_dry_run")
      expect(list).not_to include("added_outside_directory")
    end
  end

  describe "#archive_source" do
    it "archives the latest source version" do
      @project.from_directory do
        FileUtils.touch(File.join("src", "Included.java"))
        @project.commit_sources(false, "first version")

        FileUtils.touch(File.join("src", "Excluded.java"))
        @project.commit_sources(true, "patched version")

        @project.archive_sources

        file_list = `tar --list -f packages/test-project/test-project.tar.xz`.split
        expect(file_list).to include("src/Included.java")
        expect(file_list).not_to include("src/Excluded.java")
      end
    end
  end

  describe "#write_source_patches" do
    it "writes patches from the tarball generated by archive_source" do
      @project.from_directory do
        test_file = File.join("src", "Test.java")
        FileUtils.touch(test_file)
        @project.commit_sources(false, "first version")

        File.open(test_file, "w") { |f| f.write("A") }
        @project.commit_sources(true, "patched version")

        patches = @project.write_source_patches.map { |f| File.basename(f) }
        expect(patches).to include("0001-patched-version.patch")

        patch_contents = File.readlines(File.join("packages", "test-project", "0001-patched-version.patch"))
        expect(patch_contents).to include("--- a/#{test_file}\n")
      end
    end
  end

  describe "#purge_jars" do
    it "moves jars in kit/jars" do
      @project.from_directory do
        File.open(File.join("src", "test.jar"), "w") { |f| f.write("jarring") }
      end

      @project.purge_jars

      @project.from_directory do
        expect(File.symlink?(File.join("src", "test.jar"))).to be_truthy
        expect(File.readlink(File.join("src", "test.jar"))).to eq "../kit/jars/test.jar"
        expect(File.readlines(File.join("kit", "jars", "test.jar"))).to include("jarring")
      end
    end
  end
end
