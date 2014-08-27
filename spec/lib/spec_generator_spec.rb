# encoding: UTF-8

require "spec_helper"

describe Tetra::SpecGenerator do
  let(:instance) { Class.new { include Tetra::SpecGenerator }.new }

  describe "#generate" do
    it "compiles a file from a template and a value objects file" do
      template_path = File.join(instance.template_path, "test.erb")
      File.open(template_path, "w") { |io| io.puts "Hello <%= world_property %>" }

      destination = Tempfile.new("TemplateManager spec")
      destination_path = destination.path
      destination.unlink

      # binding test class
      class WorldClass
        def world_property
          "World!"
        end

        def public_binding
          binding
        end
      end

      instance.generate("test.erb", WorldClass.new.public_binding, destination_path)
      File.unlink(template_path)

      expect(File.read(destination_path)).to eq "Hello World!\n"
    end
  end
end
