# encoding: UTF-8

require "spec_helper"

describe Tetra::Archiver do

  before(:each) do
    @project_path = File.join("spec", "data", "test-project")
    Dir.mkdir(@project_path)

    Tetra::Project.init(@project_path)
    @project = Tetra::Project.new(@project_path)
  end

  after(:each) do
    FileUtils.rm_rf(@project_path)
  end

  let(:instance) { Class.new { include Tetra::Archiver }.new }

  describe "#archive" do
    it "archives a list of files" do
      @project.from_directory do
        File.open("test", "w") { |io| io.puts "test content" }

        instance.archive("test.tar.xz")
        expect(`tar -Jtf test.tar.xz`.split).to include("test")
      end
    end
  end
end
