# frozen_string_literal: true

require "spec_helper"

describe Tetra::Speccable do
  include Tetra::Mockers

  # mock
  class SpeccableTestClass
    attr_accessor :world_property

    include Tetra::Speccable

    def initialize
      @world_property = "World!"
    end
  end

  before(:each) do
    create_mock_project

    @template_path = File.join(instance.template_path, "test.spec")
    File.open(@template_path, "w") { |io| io.puts "Hello <%= world_property %>\nintentionally blank line\n" }

    @destination_path = File.join("output", "test-package", "test-package.spec")
  end

  let(:instance) { SpeccableTestClass.new }

  after(:each) do
    delete_mock_project
    FileUtils.rm_rf(@template_path)
  end

  describe "#to_spec" do
    it "generates a first version" do
      expect(instance._to_spec(@project, "test-package", "test.spec", "output")).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(@destination_path)
        expect(spec_lines).to include("Hello World!\n")
      end
    end

    it "generates a second version" do
      expect(instance._to_spec(@project, "test-package", "test.spec", "output")).to be_truthy

      @project.from_directory do
        File.open(@destination_path, "a") do |io|
          io.write("nonconflicting line\n")
        end
      end

      instance.world_property = "Mario!"

      expect(instance._to_spec(@project, "test-package", "test.spec", "output")).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(@destination_path)
        expect(spec_lines).not_to include("Hello World!\n")
        expect(spec_lines).to include("Hello Mario!\n")
        expect(spec_lines).to include("nonconflicting line\n")
      end
    end

    it "generates a conflicting version" do
      expect(instance._to_spec(@project, "test-package", "test.spec", "output")).to be_truthy

      @project.from_directory do
        spec_contents = File.read(@destination_path)
        spec_contents.gsub!(/Hello World/, "CONFLICTING!")

        File.write(@destination_path, spec_contents)
      end

      instance.world_property = "Mario!"

      expect(instance._to_spec(@project, "test-package", "test.spec", "output")).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(@destination_path)
        expect(spec_lines).to include("<<<<<<< newly generated\n")
        expect(spec_lines).to include("Hello Mario!\n")
        expect(spec_lines).to include("=======\n")
        expect(spec_lines).to include("CONFLICTING!!\n")
        expect(spec_lines).to include(">>>>>>> user edited\n")
        expect(spec_lines).to include("intentionally blank line\n")
      end
    end
  end
end
