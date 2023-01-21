# frozen_string_literal: true

require "erb"

module Tetra
  # adds methods to generate text files from an ERB template
  module Generatable
    # returns the template path
    def template_path
      File.join(File.dirname(__FILE__), "..", "template")
    end

    # generates content from an ERB template and an object binding
    def generate(template_name, object_binding)
      erb = ERB.new(File.read(File.join(template_path, template_name)), trim_mode: "<>")
      erb.result(object_binding)
    end
  end
end
